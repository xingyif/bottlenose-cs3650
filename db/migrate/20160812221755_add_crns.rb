class AddCrns < ActiveRecord::Migration
  def change
    add_column :registrations, "section_id", :integer, null: false
    add_column :reg_requests, "section_id", :integer, null: false
    create_table "course_sections", force: :cascade do |t|
      t.integer "course_id", null: false
      t.integer "crn", null: false
      t.string  "instructor", null: false
      t.string  "meeting_time"
    end
    add_index "course_sections", ["crn"], name: "index_course_sections_on_crn", unique: true, using: :btree
  end
end
