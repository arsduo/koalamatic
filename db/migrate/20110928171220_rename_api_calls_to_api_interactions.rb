class RenameApiCallsToApiInteractions < ActiveRecord::Migration
  def change
    rename_table :api_calls, :api_interactions
  end
end
