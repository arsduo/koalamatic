class CreateVersions < ActiveRecord::Migration
  def change
    create_table :versions do |t|
      t.string :app_tag
      t.string :test_gems_tag
      t.string :app_version, :length => 1000
      t.string :test_gem_versions, :length => 2000

      t.timestamps
    end

    add_index :versions, [:app_tag, :test_gems_tag]
  end
end
