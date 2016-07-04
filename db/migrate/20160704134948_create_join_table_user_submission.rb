class CreateJoinTableUserSubmission < ActiveRecord::Migration
  def change
    create_table :user_submissions do |t|
      t.integer :user_id
      t.integer :submission_id
      # t.index [:user_id, :submission_id]
      # t.index [:submission_id, :user_id]
    end
  end
end
