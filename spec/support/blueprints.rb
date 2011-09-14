TestRun.blueprint do
end

TestCase.blueprint do
end

def test_run_completed(attrs = {})
  run = attrs.delete(:run) || TestRun.make
  test_count = 5
  failure_count = 3
  run.update_attributes({
    :failure_count => failure_count,
    :test_count => test_count,
    :duration => 2.minutes,
    :tweet_id => rand(2**32).to_i,
    :publication_reason => "scheduled"
  }.merge(attrs))
  test_count.times {|i| run.test_cases << TestCase.create_from_example(make_example(i < failure_count)) }
  run
end

def test_run_in_progress(passed = 5, failed = 3)
  run = TestRun.make
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
    :backtrace => 3.times.collect { Faker::Lorem.words(5).join(" ") }, 
    :message => Faker::Lorem.words(5).join(" ")
  )
end