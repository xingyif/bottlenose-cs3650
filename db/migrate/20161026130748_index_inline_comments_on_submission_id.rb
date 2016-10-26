class IndexInlineCommentsOnSubmissionId < ActiveRecord::Migration
  def change
    add_index :inline_comments, [:submission_id, :grader_id, :line]
  end
end
