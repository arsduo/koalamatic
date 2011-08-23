class TestRun < ActiveRecord::Base
  # note: for now, we only track failures
  has_many :test_cases
  
  # how often we ideally want to run tests
  TEST_INTERVAL = 30.minutes
  # roughly how long the tests take to run
  # we subtract this from TEST_INTERVAL when looking up the last test
  # (since the record is created when the test finishes)
  TEST_PADDING = 10.minutes
  # how often we publish on twitter
  PUBLISHING_INTERVAL = 1.day

  def self.interval_to_next_run
    TEST_INTERVAL - TEST_PADDING
  end
  
  scope :within_interval, :conditions => ["created_at > ?", Time.now - TestRun.interval_to_next_run]
    
  def initialize(*args)
    super
    @failures = []
    @start_time = Time.now
  end

  def test_done(example)
    self.test_count += 1
    if example.failed?
      @failures << example
      self.failure_count = @failures.length
    end
  end

  def done
    # write out to the database
    self.duration = Time.now - @start_time
    # right now we only store details for failures
    # but may in the future store analytic data on successes
    @failures.each do |example|
      test_cases << TestCase.create_from_example(example)
    end
    
    save
  end
  
  SUCCESS_TEXT = "All's well with Facebook!"
  def summary
    text = "Run #{id} complete: "
    text += if failure_count == 0
      SUCCESS_TEXT
    else
      "We encountered #{failure_count} error#{failure_count > 1 ? "s" : ""}. (Detail page coming soon!)"
    end
  end
end
