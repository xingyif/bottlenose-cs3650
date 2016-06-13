class AddRoleToRegRequest < ActiveRecord::Migration
  def change
    add_column :reg_requests, :role, :integer, null: false, default: 0
  end
end
