class AddBacktraceToTestcases < ActiveRecord::Migration
  def change
    add_column :test_cases, :backtrace, :text
  end
end
