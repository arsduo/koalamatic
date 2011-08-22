class AddStatusToTestCase < ActiveRecord::Migration
  class TestCase < ActiveRecord::Base; end

  def change
      # test cases either pass or fail
      add_column :test_cases, :failed, :boolean
      
      # update all existing test runs to failures
      TestCase.update_all("failed = 1")
  end
end
