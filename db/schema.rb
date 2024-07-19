# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2010_01_01_192755) do
  create_table "pages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "web_id", default: 0, null: false
    t.string "locked_by", limit: 60
    t.string "name", limit: 255
    t.datetime "locked_at"
  end

  create_table "revisions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "revised_at", null: false
    t.integer "page_id", default: 0, null: false
    t.text "content", limit: 16777215
    t.string "author", limit: 60
    t.string "ip", limit: 60
    t.index ["author"], name: "index_revisions_on_author"
    t.index ["created_at"], name: "index_revisions_on_created_at"
    t.index ["page_id"], name: "index_revisions_on_page_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id"
    t.text "data"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id"
  end

  create_table "system", force: :cascade do |t|
    t.string "password", limit: 60
  end

  create_table "webs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", limit: 60, default: "", null: false
    t.string "address", limit: 60, default: "", null: false
    t.string "password", limit: 60
    t.text "additional_style"
    t.integer "allow_uploads", default: 1
    t.integer "published", default: 0
    t.integer "count_pages", default: 0
    t.string "markup", limit: 50, default: "markdown"
    t.string "color", limit: 6, default: "008B26"
    t.integer "max_upload_size", default: 100
    t.integer "safe_mode", default: 0
    t.integer "brackets_only", default: 0
  end

  create_table "wiki_files", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "web_id", null: false
    t.string "file_name", null: false
    t.string "description", null: false
  end

  create_table "wiki_references", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "page_id", default: 0, null: false
    t.string "referenced_name", limit: 255
    t.string "link_type", limit: 1, default: "", null: false
    t.index ["page_id"], name: "index_wiki_references_on_page_id"
    t.index ["referenced_name"], name: "index_wiki_references_on_referenced_name"
  end

end
