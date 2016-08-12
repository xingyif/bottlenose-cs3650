class CreateInlineComments < ActiveRecord::Migration
  def change
    create_table :inline_comments do |t|
      t.integer "submission_id",    null: false
      t.string  "title",            null: false
      t.string  "filename",         null: false
      t.integer "line",             null: false
      t.integer "grader_config_id", null: false
      t.integer "user_id"
      t.string  "label",            null: false
      t.integer "severity",         null: false
      t.string  "comment",          default: "", null: false
      t.float   "weight",           null: false
      t.boolean "suppressed",       default: false, null: false
      t.string  "info"

      t.timestamps                  null: false
    end

    add_index "inline_comments", ["filename"], name: "index_inline_comments_on_filename", using: :btree
  end
end
