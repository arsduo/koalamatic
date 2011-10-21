class TrackRequestContentInApiInteractions < ActiveRecord::Migration
  def change
    add_column :api_interactions, :request_body, :string, :length => 4000
    add_column :api_interactions, :query_string, :string, :length => 1000
  end
end
