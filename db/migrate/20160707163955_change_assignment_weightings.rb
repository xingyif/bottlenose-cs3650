class ChangeAssignmentWeightings < ActiveRecord::Migration
  def change
    change_column :assignments, :points_available, :float
    remove_column :assignments, :bucket_id
    drop_table :buckets
  end
end
