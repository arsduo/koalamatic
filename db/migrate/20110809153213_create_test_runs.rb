class CreateTestRuns < ActiveRecord::Migration
  def change
    create_table :test_runs do |t|
      t.integer :duration
      t.integer :test_count, :default => 0
      t.integer :failure_count, :default => 0
      t.timestamps
    end
  end
end
