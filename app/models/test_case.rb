class TestCase < ActiveRecord::Base
  belongs_to :test_run

  scope :failures, :conditions => {:failed => true}
  
  def self.create_from_example(example)
    create(
      :title => example.full_description,
      :failure_message => example.exception.message,
      :failed => example.failed?,
      :backtrace => example.exception.backtrace.join("\n")
    )
  end
end
