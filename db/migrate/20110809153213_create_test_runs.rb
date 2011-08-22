class CreateTestRuns < ActiveRecord::Migration
  def change
    create_table :test_runs do |t|
      t.integer :duration
      t.integer :test_count, :default => 0
      # denormalize failure count so we don't have to do joins 
      # when we just want to list test runs and their results
      t.integer :failure_count, :default => 0
      t.timestamps
    end
  end
end
