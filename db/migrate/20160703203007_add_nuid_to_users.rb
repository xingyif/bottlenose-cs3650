class AddNuidToUsers < ActiveRecord::Migration
  def change
    add_column :users, :nuid, :integer
    add_column :users, :first_name, :text
    add_column :users, :last_name, :text
    add_column :users, :nickname, :text
    add_column :users, :profile, :text
  end
end
