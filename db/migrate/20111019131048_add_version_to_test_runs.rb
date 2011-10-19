class AddVersionToTestRuns < ActiveRecord::Migration
  def change
    add_column :test_runs, :version_id, :integer
  end
end
