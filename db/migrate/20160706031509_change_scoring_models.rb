class ChangeScoringModels < ActiveRecord::Migration
  def change
    rename_table :best_subs, :subs_for_gradings
    

    add_column :submissions, :score, :float
    remove_column :submissions, :auto_score, :integer
    remove_column :submissions, :teacher_score, :integer
    remove_column :submissions, :teacher_notes, :text
    remove_column :submissions, :grading_output, :string
    remove_column :submissions, :grading_uid, :integer

    create_table "grader_configs", force: :cascade do |t|
      t.string   "type"
      t.float    "avail_score"
      t.string   "params"
    end

    create_table "assignment_graders", force: :cascade do |t|
      t.integer "assignment_id", null: false
      t.integer "grader_config_id", null: false
      t.integer "order"
    end
    add_index "assignment_graders", ["assignment_id"], name: "index_assignment_graders_on_assignment_id", using: :btree

    create_table "graders", force: :cascade do |t|
      t.integer  "grader_config_id", null: false
      t.integer  "submission_id", null: false
      t.string   "grading_output"
      t.text     "notes"
      t.float    "score"
      t.float    "out_of"
      t.datetime "updated_at"
      t.boolean  "available", default: false
    end
    add_index "graders", ["submission_id"], name: "index_graders_on_submission_id", using: :btree

  end
end
