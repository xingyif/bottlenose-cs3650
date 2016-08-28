class AddRelatedAssignmentToAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :related_assignment_id, :integer
    add_index :assignments, [:course_id]
  end
end
