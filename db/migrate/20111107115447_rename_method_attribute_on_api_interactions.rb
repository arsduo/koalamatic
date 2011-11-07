class RenameMethodAttributeOnApiInteractions < ActiveRecord::Migration
  def change
    rename_column :api_interactions, :method, :verb
  end
end
