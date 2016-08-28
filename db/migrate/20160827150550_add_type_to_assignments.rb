class AddTypeToAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :type, :string, null: false, default: "files"
    add_column :submissions, :type, :string, null: false, default: "files"
  end
end
