class TestCase < ActiveRecord::Base
  belongs_to :test_run

  scope :failures, :conditions => {:failed => true}
end
