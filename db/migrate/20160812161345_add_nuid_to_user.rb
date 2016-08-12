class AddNuidToUser < ActiveRecord::Migration
  def up
    add_column :users, :nuid, :integer
    change_column :users, :email, :string, :null => true

    add_index :users, ["nuid"], name: "index_users_on_nuid", unique: true, using: :btree
  end
  def down
    remove_column :users, :nuid
    change_column :users, :email, :string, :null => false

    remove_index :users, name: "index_users_on_nuid"
  end
end
