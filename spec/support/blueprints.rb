TestRun.blueprint do

end

TestCase.blueprint do
  title { Faker::Lorem.words(4).join(" ") }
  failure_message { Faker::Lorem.words(4).join(" ") }
  test_run { TestRun.make }
  backtrace { Faker::Lorem.words(20).join(" ") }
  failed { true } 
end

def test_run_with_examples
  test_count = 5
  failure_count = 3
  TestRun.make(
    :test_cases => test_count.times.collect { TestCase.make(:test_run => object) },
    :failure_count => failure_count,
    :test_count => test_count,
    :duration => 2.minutes
  )
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