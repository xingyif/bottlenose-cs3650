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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160812161345) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assignment_graders", force: :cascade do |t|
    t.integer "assignment_id",    null: false
    t.integer "grader_config_id", null: false
    t.integer "order"
  end

  add_index "assignment_graders", ["assignment_id"], name: "index_assignment_graders_on_assignment_id", using: :btree

  create_table "assignments", force: :cascade do |t|
    t.string   "name",                                 null: false
    t.datetime "due_date",                             null: false
    t.string   "assignment_file_name"
    t.string   "grading_file_name"
    t.text     "assignment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "secret_dir"
    t.boolean  "hide_grading",         default: false
    t.integer  "assignment_upload_id"
    t.integer  "grading_upload_id"
    t.integer  "blame_id"
    t.integer  "solution_upload_id"
    t.string   "tar_key"
    t.integer  "course_id",                            null: false
    t.boolean  "team_subs"
    t.integer  "max_attempts"
    t.integer  "rate_per_hour"
    t.float    "points_available"
    t.integer  "lateness_config_id"
    t.datetime "available"
  end

  create_table "courses", force: :cascade do |t|
    t.string   "name",                               null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "footer"
    t.integer  "term_id"
    t.integer  "sub_max_size",       default: 5,     null: false
    t.boolean  "public",             default: false, null: false
    t.integer  "team_min"
    t.integer  "team_max"
    t.integer  "total_late_days"
    t.integer  "lateness_config_id", default: 0,     null: false
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "grader_configs", force: :cascade do |t|
    t.string "type"
    t.float  "avail_score"
    t.string "params"
  end

  create_table "graders", force: :cascade do |t|
    t.integer  "grader_config_id",                 null: false
    t.integer  "submission_id",                    null: false
    t.string   "grading_output"
    t.text     "notes"
    t.float    "score"
    t.float    "out_of"
    t.datetime "updated_at"
    t.boolean  "available",        default: false
  end

  add_index "graders", ["submission_id"], name: "index_graders_on_submission_id", using: :btree

  create_table "inline_comments", force: :cascade do |t|
    t.integer  "submission_id",                    null: false
    t.string   "title",                            null: false
    t.string   "filename",                         null: false
    t.integer  "line",                             null: false
    t.integer  "grader_config_id",                 null: false
    t.integer  "user_id"
    t.string   "label",                            null: false
    t.integer  "severity",                         null: false
    t.string   "comment",          default: "",    null: false
    t.float    "weight",                           null: false
    t.boolean  "suppressed",       default: false, null: false
    t.string   "info"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  add_index "inline_comments", ["filename"], name: "index_inline_comments_on_filename", using: :btree

  create_table "lateness_configs", force: :cascade do |t|
    t.string  "type"
    t.integer "days_per_assignment"
    t.integer "percent_off"
    t.integer "frequency"
    t.integer "max_penalty"
  end

  create_table "reg_requests", force: :cascade do |t|
    t.integer  "course_id"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "role",       default: 0, null: false
  end

  create_table "registrations", force: :cascade do |t|
    t.integer  "course_id",                  null: false
    t.integer  "user_id",                    null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "show_in_lists"
    t.string   "tags",          default: ""
    t.integer  "role",          default: 0,  null: false
  end

  add_index "registrations", ["course_id"], name: "index_registrations_on_course_id", using: :btree
  add_index "registrations", ["user_id"], name: "index_registrations_on_user_id", using: :btree

  create_table "submissions", force: :cascade do |t|
    t.integer  "assignment_id",                       null: false
    t.integer  "user_id",                             null: false
    t.string   "secret_dir"
    t.string   "file_name"
    t.text     "student_notes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "ignore_late_penalty", default: false
    t.integer  "upload_id"
    t.integer  "upload_size",         default: 0,     null: false
    t.integer  "team_id"
    t.integer  "comments_upload_id"
    t.boolean  "stale_team"
    t.float    "score"
  end

  add_index "submissions", ["assignment_id"], name: "index_submissions_on_assignment_id", using: :btree
  add_index "submissions", ["user_id", "assignment_id"], name: "index_submissions_on_user_id_and_assignment_id", using: :btree
  add_index "submissions", ["user_id"], name: "index_submissions_on_user_id", using: :btree

  create_table "subs_for_gradings", force: :cascade do |t|
    t.integer "user_id",       null: false
    t.integer "assignment_id", null: false
    t.integer "submission_id", null: false
  end

  add_index "subs_for_gradings", ["user_id", "assignment_id"], name: "unique_sub_per_user_assignment", unique: true, using: :btree

  create_table "team_users", force: :cascade do |t|
    t.integer  "team_id"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "team_users", ["team_id", "user_id"], name: "unique_team_memebers", unique: true, using: :btree

  create_table "teams", force: :cascade do |t|
    t.integer  "course_id"
    t.date     "start_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date     "end_date"
  end

  create_table "terms", force: :cascade do |t|
    t.string   "name"
    t.boolean  "archived",   default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "uploads", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "file_name"
    t.string   "secret_key"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "uploads", ["secret_key"], name: "index_uploads_on_secret_key", unique: true, using: :btree

  create_table "user_submissions", force: :cascade do |t|
    t.integer "user_id"
    t.integer "submission_id"
  end

  create_table "users", force: :cascade do |t|
    t.string   "name",                                null: false
    t.string   "email"
    t.boolean  "site_admin"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.string   "username"
    t.text     "first_name"
    t.text     "last_name"
    t.text     "nickname"
    t.text     "profile"
    t.integer  "nuid"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["nuid"], name: "index_users_on_nuid", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["username"], name: "index_users_on_username", unique: true, using: :btree

end
