class CreateApiCalls < ActiveRecord::Migration
  def change
    create_table :api_calls do |t|
      # request info
      t.string :method
      t.string :request_body, :limit => 2000 # shouldn't need more than that
      t.string :path, :limit => 400
      t.string :host
      t.boolean :ssl
      t.string :query, :limit => 2000
      t.column :duration, :double
      
      # response info
      t.integer :response_status

      # analysis
      t.boolean :analyzed, :default => false
      t.timestamps
    end
  end
end
