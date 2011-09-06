class AddPublishingDetailsToRuns < ActiveRecord::Migration
  def change
    add_column :test_runs, :tweet_id, :integer
    add_column :test_runs, :publication_reason, :string
  end
end
