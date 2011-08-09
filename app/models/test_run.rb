class TestRun < ActiveRecord::Base
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
        :failure_message => example.exception.message
      )
    end
    
    save!
  end
  
  def elapsed_time
    raise StandardError, "Tests aren't done running!" unless @end_time
    @end_time - @start_time
  end
end
