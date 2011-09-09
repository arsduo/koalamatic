class TestRun < ActiveRecord::Base
  # note: for now, we only track failures
  has_many :test_cases
  
  # how often we ideally want to run tests
  TEST_INTERVAL = 60.minutes
  # roughly how long the tests take to run
  # we subtract this from TEST_INTERVAL when looking up the last test
  # (since the record is created when the test finishes)
  TEST_PADDING = 10.minutes
  # how often we publish on twitter
  PUBLISHING_INTERVAL = 1.day
  DIFFERENT_RESULTS_REASON = "different_results"
  SCHEDULED_REASON = "scheduled"
  
  def self.interval_to_next_run
    TEST_INTERVAL - TEST_PADDING
  end
  
  def self.time_for_next_run?
    logger.info("created_at > #{(Time.now - interval_to_next_run).to_i}")
    logger.info(TestRun.last.created_at.to_i)
    logger.info(TestRun.where(["created_at > ?", Time.now - interval_to_next_run]).limit(1).first.inspect)
    logger.info(!!TestRun.where(["created_at > ?", Time.now - interval_to_next_run]).limit(1).first)
    !TestRun.where(["created_at > ?", Time.now - interval_to_next_run]).limit(1).first
  end
  
  scope :published, :conditions => "tweet_id is not null", :order => "id desc"
  scope :scheduled, :conditions => "publication_reason  = 'scheduled'", :order => "id desc"
  
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
  
  # PUBLISHING  
  SUCCESS_TEXT = "All's well with Facebook!"
  def summary
    text = "Run #{id} complete: "
    text += if failure_count == 0
      SUCCESS_TEXT
    else
      "We encountered #{failure_count} error#{failure_count > 1 ? "s" : ""}. (Detail page coming soon!)"
    end
  end
  
  def previous_run
    @previous ||= TestRun.where(["id < ?", self.id]).order("id desc").limit(1).first
  end
  
  def publishable_by_interval?
    (last_run = TestRun.last_scheduled_publication) ? last_run.created_at < Time.now - PUBLISHING_INTERVAL : true
  end
  
  def publishable_by_results?
    # this needs to be refined to examine the actual contents of the errors
    !previous_run || failure_count != previous_run.failure_count
  end
  
  def publishable?
    # see if it's time to publish again
    # is it bad form for a ? method to return strings for later use?
    if publishable_by_interval?
      Rails.logger.info("Interval publishing!")
      SCHEDULED_REASON
    # alternately, see if this run has produced different results
    elsif publishable_by_results?
      Rails.logger.info("Results publishing!")
      DIFFERENT_RESULTS_REASON
    else
      Rails.logger.info("Not publishing!")
      false
    end
  end
  
  def publish_if_appropriate!
    if reason = self.publishable?
      Rails.logger.info("Publishing for #{reason.inspect}")
      self.publication_reason = reason
      publication = Twitter.update(summary)
      Rails.logger.info("Publish: #{publication}")
      self.tweet_id = publication.id
      status = self.save
      Rails.logger.info("Save status: #{status}")
      Rails.logger.info("Errors: #{self.errors.inspect}")
    end
  end
  
  # class methods
  
  def self.most_recently_published
    published.first
  end
  
  def self.last_scheduled_publication
    published.scheduled.first
  end
  
end
