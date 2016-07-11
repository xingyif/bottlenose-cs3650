class AddAvaliableDateToAssignment < ActiveRecord::Migration
  def change
    add_column :assignments, :available, :datetime
  end
end
