class MakeTweetIdBigint < ActiveRecord::Migration
  def up
    change_column :test_runs, :tweet_id, :bigint
  end

  def down
    change_column :test_runs, :tweet_id, :integer
  end
end
