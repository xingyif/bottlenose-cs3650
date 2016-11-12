class IndexUserSubmissionsNonUnique < ActiveRecord::Migration
  def change
    remove_index :user_submissions, [:submission_id]
    add_index :user_submissions, [:submission_id] # For team submissions, it's not going to be unique...
  end
end
