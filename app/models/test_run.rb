class TestRun < ActiveRecord::Base
  # note: for now, we only track failures
  has_many :test_cases
  
  def initialize
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
    
    save!
  end
    
  def summary
    text = "Run #{id} complete: "
    text += if failure_count == 0
      "All's well with Facebook!"
    else
      "We encountered #{failure_count} error#{failure_count > 1 ? "s" : ""}. (Detail page coming soon!)"
    end

    text
  end
end
