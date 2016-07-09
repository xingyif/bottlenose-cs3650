class CreateLatenessConfigs < ActiveRecord::Migration
  def change
    create_table :lateness_configs do |t|
      t.string "type"
      # stop accepting assignments this many days late
      t.integer "days_per_assignment"
      # percentage policy
      t.integer "percent_off" # deduct this percentage
      t.integer "frequency" # each this-many days
      t.integer "max_penalty" # to a max of this percentage
    end

    remove_column :courses, :late_options, :string
    add_column :courses, :total_late_days, :integer # allow this many late days per semester
    add_column :assignments, :lateness_config_id, :integer, :null => false
    add_column :courses, :lateness_config_id, :integer, :null => false # default lateness policy
  end
  def up
    change_column :assignments, :due_date, :datetime
  end

  def down
    change_column :assignments, :due_date, :date
  end
end
