# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20111019131048) do

  create_table "api_interactions", :force => true do |t|
    t.string   "method"
    t.string   "path",            :limit => 400
    t.string   "host"
    t.boolean  "ssl"
    t.float    "duration"
    t.integer  "response_status"
    t.boolean  "analyzed",                       :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "primary_object"
  end

  create_table "test_cases", :force => true do |t|
    t.string   "title",           :limit => 4000
    t.string   "failure_message", :limit => 4000
    t.integer  "test_run_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "backtrace"
    t.integer  "error_status"
  end

  add_index "test_cases", ["test_run_id"], :name => "index_test_cases_on_test_run_id"

  create_table "test_runs", :force => true do |t|
    t.integer  "duration"
    t.integer  "test_count",                          :default => 0
    t.integer  "failure_count",                       :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "tweet_id",               :limit => 8
    t.string   "publication_reason"
    t.integer  "verified_failure_count",              :default => 0
    t.integer  "version_id"
  end

  create_table "versions", :force => true do |t|
    t.string   "app_tag"
    t.string   "test_gems_tag"
    t.string   "app_version"
    t.string   "test_gem_versions"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "versions", ["app_tag", "test_gems_tag"], :name => "index_versions_on_app_tag_and_test_gems_tag"

end
