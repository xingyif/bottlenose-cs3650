class IndexUserSubmissions < ActiveRecord::Migration
  def change
    add_index :user_submissions, [:user_id, :submission_id], unique: true 
    add_index :user_submissions, [:user_id]
    add_index :user_submissions, [:submission_id], unique: true 
  end
end
