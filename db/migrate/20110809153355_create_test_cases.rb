class CreateTestCases < ActiveRecord::Migration
  def change
    create_table :test_cases do |t|
      t.string :title
      t.string :failure_message
      t.integer :test_run_id
       
      t.timestamps
    end
    
    add_index :test_cases, [:test_run_id]
  end
end
