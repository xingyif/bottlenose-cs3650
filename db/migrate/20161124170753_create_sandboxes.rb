class CreateSandboxes < ActiveRecord::Migration
  def change
    create_table :sandboxes do |t|
      t.string :name
      t.integer :submission_id

      t.timestamps null: false
    end
  end
end
