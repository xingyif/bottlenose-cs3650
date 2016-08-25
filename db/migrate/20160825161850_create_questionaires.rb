class CreateQuestionaires < ActiveRecord::Migration
  def change
    create_table :questionaires do |t|
      t.string :name, null: false
      t.datetime :due_date, null: false
      t.datetime :available
      t.integer :course_id, null: false
      t.integer :assignment_id
      t.integer :lateness_config_id, null: false
      t.integer :blame_id, null: false
      t.float :points_available, null: false
      t.integer :max_attempts
      t.boolean :team_subs

      t.timestamps null: false
    end
    add_index :questionaires, :assignment_id
  end
end
