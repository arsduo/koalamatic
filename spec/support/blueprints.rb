require 'base/test_run'
require 'base/test_case'
require 'base/version'

TEST_RUN_BLUEPRINT = Proc.new do
end

Koalamatic::Base::TestRun.blueprint &TEST_RUN_BLUEPRINT
Facebook::TestRun.blueprint do
  TEST_RUN_BLUEPRINT.call
end

TEST_CASE_BLUEPRINT = Proc.new do
end

Koalamatic::Base::TestCase.blueprint &TEST_CASE_BLUEPRINT

Koalamatic::Base::Version.blueprint do
  app_tag { Digest::MD5.hexdigest(Time.now.to_s) }
  test_gems_tag { Digest::MD5.hexdigest(Time.now.to_s + rand(1000).to_s) }
end

def test_run_completed(attrs = {})
  run = attrs.delete(:run) || Koalamatic::Base::TestRun.make
  test_count = 5
  failure_count = 3
  run.update_attributes({
    :failure_count => failure_count,
    :verified_failure_count => failure_count,
    :test_count => test_count,
    :duration => 2.minutes,
    :tweet_id => rand(2**32).to_i,
    :publication_reason => "scheduled"
  }.merge(attrs))
  test_count.times {|i| run.test_cases << Koalamatic::Base::TestCase.create_from_example(make_example(i < failure_count)) }
  run
end

def test_run_in_progress(passed = 5, failed = 3)
  run = Koalamatic::Base::TestRun.make
  passed.times.each { run.test_done(make_example(false)) }
  failed.times.each { run.test_done(make_example(true)) }
  run
end

def make_example(failure = false)
  example = stub("example")
  example.stubs(:failed?).returns(failure)
  example.stubs(:full_description).returns(Faker::Lorem.words(5).join(" "))
  example.stubs(:exception).returns(failure ? make_exception : nil) 
  example.stubs(:original_exception).returns(failure ? make_exception : nil) 
  
  # stub our monkey-patches too
  example.stubs(:phantom_exception?).returns(false)
  example.stubs(:different_exceptions?).returns(false)
  example.stubs(:verified_exception?).returns(true)
  
  example
end

def make_exception  
  exception = nil
  begin; raise StandardError, Faker::Lorem.words(5).join(" "); rescue StandardError => exception; end
  # add Koala to the backtrace to generate some interesting lines
  exception.stubs(:backtrace).returns(8.times.collect { Faker::Lorem.words(5).join(" ") + (rand > 0.5 ? " koala" : "") })
  exception
end

def make_url(attrs = {})
  stub("url", {
    :path => Faker::Lorem.words(2).join("/"),
    :host => Faker::Lorem.words(3).join("."),
    :query => Faker::Lorem.words(3).join("&"),
    :inferred_port => 443
  }.merge(attrs || {}))
end

def make_env(attrs = {})
  {
    :body => 5.times.inject({}) {|hash, i| hash[Faker::Lorem.words(1).join] = Faker::Lorem.words(1).join; hash},
    :url => make_url(attrs.delete(:url)),
    :method => "get"
  }.merge(attrs || {})  
end