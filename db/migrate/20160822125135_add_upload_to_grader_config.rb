class AddUploadToGraderConfig < ActiveRecord::Migration
  def change
    add_column :grader_configs, :upload_id, :integer
    add_index :assignment_graders, [:assignment_id, :grader_config_id], :unique => true, :name => "unique_assignment_graders"
  end
end
