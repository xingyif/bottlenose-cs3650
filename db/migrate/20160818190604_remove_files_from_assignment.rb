class RemoveFilesFromAssignment < ActiveRecord::Migration
  def change
    remove_column :assignments, :grading_file_name, :string
    remove_column :assignments, :grading_upload_id, :integer
    remove_column :assignments, :solution_upload_id, :integer
  end
end
