class AddObjectToApiInteraction < ActiveRecord::Migration
  def change
    add_column :api_interactions, :primary_object, :string
  end
end