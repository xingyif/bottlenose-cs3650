class ChangeInlineCommentsGraders < ActiveRecord::Migration
  def change
    rename_column :inline_comments, :grader_config_id, :grader_id
  end
end
