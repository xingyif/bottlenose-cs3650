class AddUniquenessIndexToTeams < ActiveRecord::Migration
  def change
    add_index :team_users, [:team_id, :user_id], :unique => true, :name => "unique_team_memebers"
  end
end
