class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.integer :questionaire_id, null: false
      t.string :type, null: false
      t.string :prompt, null: false
      t.string :options
      t.float :weight, null: false

      t.timestamps null: false
    end
    add_index :questions, :questionaire_id
  end
end
