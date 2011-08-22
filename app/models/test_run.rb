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
      puts "Adding to failures #{self.failure_count}"
      @failures << example
      self.failure_count = @failures.length
      puts self.failure_count
    end
  end

  def done
    # write out to the database
    self.duration = Time.now - @start_time
    @failures.each do |example|
      test_cases << TestCase.create(
        :title => example.full_description,
        :failure_message => example.exception.message,
        :failed => true,
        :backtrace => example.exception.backtrace.join("\n")
      )
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
