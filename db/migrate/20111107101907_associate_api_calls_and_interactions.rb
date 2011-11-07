class AssociateApiCallsAndInteractions < ActiveRecord::Migration
  def change
    add_column :api_interactions, :api_call_id, :integer
  end
end