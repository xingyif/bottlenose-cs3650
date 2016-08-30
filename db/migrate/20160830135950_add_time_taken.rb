class AddTimeTaken < ActiveRecord::Migration
  def change
    add_column :submissions, :time_taken, :float
    add_column :assignments, :request_time_taken, :boolean, default: false
  end
end
