class AddUniquenessIndexToSubs < ActiveRecord::Migration
  def change
    add_index :subs_for_gradings, [:user_id, :assignment_id], :unique => true, :name => "unique_sub_per_user_assignment"
  end
end
