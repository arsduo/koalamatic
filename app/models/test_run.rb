class TestRun < ActiveRecord::Base
  # note: for now, we only track failures
  has_many :test_cases

  def start
    @failures = []
    @start_time = Time.now
  end

  def test_done(example)
    self.test_count += 1
    @failures << example if example.failed?
  end

  def done
    @end_time = Time.now

    # write out to the database
    self.duration = elapsed_time
    self.failure_count = @failures.length
    @failures.each do |example|
      test_cases << TestCase.create(
        :title => example.full_description,
        :failure_message => example.exception.message,
        :backtrace => example.exception.backtrace.join("\n")
      )
    end
    
    save!
  end
  
  def elapsed_time
    raise StandardError, "Tests aren't done running!" unless @end_time
    @end_time - @start_time
  end
  
  def summary
    text = "Run complete: "
    text += if run.failure_count == 0
      "All's well with Facebook!"
    else
      "We encountered #{run.failure_count} error#{run.failure_count > 1 ? "s" : ""}. (Detail page coming soon!)"
    end

    text
  end
end
