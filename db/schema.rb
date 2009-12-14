# This file is auto-generated from the current state of the database. Instead of editing this file,
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.


ActiveRecord::Schema.define(:version => 20091124161608) do

  create_table "cached_pages", :force => true do |t|
    t.text     "path"
    t.datetime "expire_after"
    t.datetime "created_at"
    t.integer  "node_id"
    t.integer  "site_id"
  end

  create_table "cached_pages_nodes", :id => false, :force => true do |t|
    t.integer "cached_page_id"
    t.integer "node_id"
  end

  create_table "caches", :force => true do |t|
    t.datetime "updated_at"
    t.integer  "visitor_id"
    t.string   "visitor_groups", :limit => 200
    t.string   "kpath",          :limit => 200
    t.integer  "context"
    t.text     "content"
    t.integer  "site_id"
  end

  create_table "comments", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "status",                       :default => 70, :null => false
    t.integer  "discussion_id"
    t.integer  "reply_to"
    t.integer  "user_id"
    t.string   "title",         :limit => 250, :default => "", :null => false
    t.text     "text",                                         :null => false
    t.string   "author_name",   :limit => 300
    t.integer  "site_id"
    t.string   "ip",            :limit => 200
  end

  create_table "contact_contents", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "version_id"
    t.string   "first_name", :limit => 60,  :default => "", :null => false
    t.string   "name",       :limit => 60,  :default => "", :null => false
    t.text     "address"
    t.string   "zip",        :limit => 20,  :default => "", :null => false
    t.string   "city",       :limit => 60,  :default => "", :null => false
    t.string   "telephone",  :limit => 60,  :default => "", :null => false
    t.string   "mobile",     :limit => 60,  :default => "", :null => false
    t.string   "email",      :limit => 60,  :default => "", :null => false
    t.date     "birthday"
    t.integer  "site_id"
    t.string   "country",    :limit => 100
  end

  create_table "data_entries", :force => true do |t|
    t.integer  "site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.datetime "date"
    t.text     "text"
    t.decimal  "value_a",    :precision => 24, :scale => 8
    t.integer  "node_a_id"
    t.integer  "node_b_id"
    t.integer  "node_c_id"
    t.integer  "node_d_id"
    t.decimal  "value_b",    :precision => 24, :scale => 8
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "discussions", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "node_id"
    t.boolean  "inside",                   :default => false
    t.boolean  "open",                     :default => true
    t.string   "lang",       :limit => 10, :default => "",    :null => false
    t.integer  "site_id"
  end

  create_table "document_contents", :force => true do |t|
    t.string  "type",         :limit => 32
    t.integer "version_id"
    t.string  "name",         :limit => 200, :default => "", :null => false
    t.string  "content_type", :limit => 40
    t.string  "ext",          :limit => 20
    t.integer "size"
    t.integer "width"
    t.integer "height"
    t.integer "site_id"
    t.text    "exif_json"
  end

  create_table "dyn_attributes", :force => true do |t|
    t.integer "owner_id"
    t.string  "owner_table"
    t.string  "key"
    t.text    "value"
  end

  add_index "dyn_attributes", ["owner_id"], :name => "index_dyn_attributes_on_owner_id"
  add_index "dyn_attributes", ["owner_table"], :name => "index_dyn_attributes_on_owner_table"

  create_table "groups", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",       :limit => 20, :default => "", :null => false
    t.integer  "site_id"
  end

  create_table "groups_users", :id => false, :force => true do |t|
    t.integer "group_id", :null => false
    t.integer "user_id",  :null => false
  end

  create_table "iformats", :force => true do |t|
    t.string   "name",       :limit => 40
    t.integer  "site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "size"
    t.integer  "gravity"
    t.integer  "width"
    t.integer  "height"
    t.string   "popup",      :limit => 120
  end

  create_table "links", :force => true do |t|
    t.integer  "source_id"
    t.integer  "target_id"
    t.integer  "relation_id"
    t.integer  "status"
    t.string   "comment",     :limit => 60
    t.datetime "date"
  end

  create_table "nodes", :force => true do |t|
    t.string   "type",         :limit => 32
    t.datetime "event_at"
    t.string   "kpath",        :limit => 16
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",                                        :null => false
    t.integer  "section_id"
    t.integer  "parent_id"
    t.string   "name",         :limit => 200
    t.string   "skin"
    t.integer  "inherit"
    t.integer  "rgroup_id"
    t.integer  "wgroup_id"
    t.integer  "dgroup_id"
    t.datetime "publish_from"
    t.datetime "log_at"
    t.string   "ref_lang",     :limit => 10,  :default => "",    :null => false
    t.string   "alias",        :limit => 400
    t.text     "fullpath"
    t.boolean  "custom_base",                 :default => false
    t.text     "basepath"
    t.integer  "site_id"
    t.integer  "zip"
    t.integer  "project_id"
    t.float    "position",                    :default => 0.0
    t.integer  "vclass_id"
    t.integer  "custom_a"
    t.integer  "custom_b"
    t.text     "vhash"
    t.boolean  "delta",                       :default => true,  :null => false
  end

  create_table "relations", :force => true do |t|
    t.string  "source_role",   :limit => 32
    t.string  "source_kpath",  :limit => 16
    t.boolean "source_unique"
    t.string  "source_icon",   :limit => 200
    t.string  "target_role",   :limit => 32
    t.string  "target_kpath",  :limit => 16
    t.boolean "target_unique"
    t.string  "target_icon",   :limit => 200
    t.integer "site_id",                      :null => false
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "site_attributes", :force => true do |t|
    t.integer "owner_id"
    t.string  "key"
    t.text    "value"
  end

  add_index "site_attributes", ["owner_id"], :name => "index_site_attributes_on_owner_id"

  create_table "sites", :force => true do |t|
    t.string   "host"
    t.integer  "root_id"
    t.integer  "su_id"
    t.integer  "anon_id"
    t.integer  "public_group_id"
    t.integer  "site_group_id"
    t.string   "name"
    t.boolean  "authentication"
    t.string   "languages"
    t.string   "default_lang"
    t.boolean  "http_auth"
    t.boolean  "auto_publish"
    t.integer  "redit_time"
    t.datetime "formats_updated_at"
  end

  create_table "template_contents", :force => true do |t|
    t.integer "site_id"
    t.integer "node_id"
    t.string  "skin_name"
    t.string  "format"
    t.string  "tkpath"
    t.string  "klass"
    t.string  "mode"
  end

  create_table "users", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "login",             :limit => 20
    t.string   "crypted_password",  :limit => 40
    t.string   "first_name",        :limit => 60
    t.string   "name",              :limit => 60
    t.string   "email",             :limit => 60
    t.string   "time_zone"
    t.integer  "site_id"
    t.integer  "status"
    t.integer  "contact_id"
    t.string   "lang",              :limit => 10, :default => "", :null => false
    t.string   "persistence_token"
    t.string   "password_salt"
  end

  create_table "versions", :force => true do |t|
    t.string   "type",         :limit => 32
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "node_id",                                    :null => false
    t.integer  "user_id",                                    :null => false
    t.string   "lang",         :limit => 10, :default => "", :null => false
    t.datetime "publish_from"
    t.text     "comment"
    t.text     "title"
    t.text     "summary"
    t.text     "text"
    t.integer  "status",                     :default => 70, :null => false
    t.integer  "number",                     :default => 1,  :null => false
    t.integer  "content_id"
    t.integer  "site_id"
  end

  if Zena::Db.adapter == 'mysql'
    execute "ALTER TABLE versions ENGINE = MyISAM"
    execute "CREATE FULLTEXT INDEX index_versions_on_title_and_text_and_summary ON versions (title,text,summary)"
  end

  create_table "virtual_classes", :force => true do |t|
    t.string  "name"
    t.string  "kpath",                  :limit => 16
    t.string  "real_class",             :limit => 16
    t.string  "icon",                   :limit => 200
    t.integer "create_group_id"
    t.integer "site_id",                               :null => false
    t.boolean "auto_create_discussion"
    t.text    "dyn_keys"
  end

  create_table "zips", :id => false, :force => true do |t|
    t.integer "site_id"
    t.integer "zip"
  end

end
