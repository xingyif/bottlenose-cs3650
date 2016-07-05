class AddStaleTeamToSubmission < ActiveRecord::Migration
  def change
    add_column :submissions, :stale_team, :boolean
  end
end
