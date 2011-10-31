class CreateApiCalls < ActiveRecord::Migration
  def change
    create_table :api_calls do |t|
      t.string :verb
      t.string :category
      t.string :path_format
      t.string :object
      t.string :subject
      t.string :description

      t.timestamps
    end
  end
end
