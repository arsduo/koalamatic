class LinkTestRunsAndApiInteractions < ActiveRecord::Migration
  def change
    add_column :api_interactions, :test_run_id, :integer
  end
end
