class TrackErrorStatus < ActiveRecord::Migration

  class TestCase < ActiveRecord::Base
    module ErrorStatus
      NONE = 0 # no errors
      UNKNOWN = 1 # pre-verification mostly
      PHANTOM = 2 # no error on rerun
      INCONSISTENT = 3 # two different errors
      VERIFIED = 4 # rerun produced the same error
    end
  end

  def up
    add_column :test_cases, :error_status, :integer
    TestCase.update_all("error_status = #{TestCase::ErrorStatus::UNKNOWN}", "failed = true")
    remove_column :test_cases, :failed
  end
  
  def down
    add_column :test_cases, :failed, :boolean
    TestCase.update_all("failed = 1", "error_status > 0")
    remove_column :test_cases, :error_status
  end
end
