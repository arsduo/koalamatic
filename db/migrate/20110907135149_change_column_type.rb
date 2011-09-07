class ChangeColumnType < ActiveRecord::Migration
  def up
    change_column :test_cases, :failure_message, :string, :limit => 4000
    change_column :test_cases, :title, :string, :limit => 4000
  end

  def down
    change_column :test_cases, :failure_message, :string, :limit => 255
    change_column :test_cases, :title, :string, :limit => 255
  end
end
