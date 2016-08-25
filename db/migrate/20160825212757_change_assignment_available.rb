class ChangeAssignmentAvailable < ActiveRecord::Migration
  def change
    change_column :assignments, :available, :datetime, null: false
  end
end
