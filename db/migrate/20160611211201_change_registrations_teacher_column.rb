class ChangeRegistrationsTeacherColumn < ActiveRecord::Migration
  def change
    remove_column :registrations, :teacher
    add_column :registrations, :role, :integer, null: false, default: 0
  end
end
