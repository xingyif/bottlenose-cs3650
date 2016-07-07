class RemoveScoreFromSubsForGrading < ActiveRecord::Migration
  def change
    remove_column :subs_for_gradings, :score, :float
  end
end
