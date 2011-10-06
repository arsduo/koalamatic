require 'base/test_run'
require 'base/test_case'

TEST_RUN_BLUEPRINT = Proc.new do
end

Koalamatic::Base::TestRun.blueprint &TEST_RUN_BLUEPRINT
Facebook::TestRun.blueprint do
  TEST_RUN_BLUEPRINT.call
end

TEST_CASE_BLUEPRINT = Proc.new do
end

Koalamatic::Base::TestCase.blueprint &TEST_CASE_BLUEPRINT

def test_run_completed(attrs = {})
  run = attrs.delete(:run) || Koalamatic::Base::TestRun.make
  test_count = 5
  failure_count = 3
  run.update_attributes({
    :failure_count => failure_count,
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
  example.stubs(:exception).returns(make_exception) if failure
  example
end

def make_exception
  stub("exception", 
    # add Koala to the backtrace to generate some interesting lines
    :backtrace => 8.times.collect { Faker::Lorem.words(5).join(" ") + (rand > 0.5 ? " koala" : "") }, 
    :message => Faker::Lorem.words(5).join(" ")
  )
end