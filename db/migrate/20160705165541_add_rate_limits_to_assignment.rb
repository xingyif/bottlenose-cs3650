class AddRateLimitsToAssignment < ActiveRecord::Migration
  def change
    add_column :assignments, :max_attempts, :integer
    add_column :assignments, :rate_per_hour, :integer
  end
end
