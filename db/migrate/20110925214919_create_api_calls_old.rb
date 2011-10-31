class CreateApiCallsOld < ActiveRecord::Migration
  def change
    create_table :api_calls do |t|
      # request info
      t.string :method
      #t.string :request_body, :limit => 2000 # shouldn't need more than that
      t.string :path, :limit => 400
      t.string :host
      t.boolean :ssl
      #t.string :query, :limit => 2000
      # postgres knows it as float8
      t.column :duration, (Rails.env.production? ? :float8 : :double)
      
      # response info
      t.integer :response_status

      # analysis
      t.boolean :analyzed, :default => false
      t.timestamps
    end
  end
end
