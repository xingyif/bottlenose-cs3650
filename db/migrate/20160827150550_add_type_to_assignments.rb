class AddTypeToAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :type, :string, null: false, default: "Files"
    add_column :submissions, :type, :string, null: false, default: "Files"
  end
end
