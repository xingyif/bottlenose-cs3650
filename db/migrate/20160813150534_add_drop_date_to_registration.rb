class AddDropDateToRegistration < ActiveRecord::Migration
  def change
    add_column :registrations, :dropped_date, :datetime
  end
end
