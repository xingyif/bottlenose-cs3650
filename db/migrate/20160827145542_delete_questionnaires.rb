class DeleteQuestionnaiuestionnaires < ActiveRecord::Migration
  def change
    drop_table :questionnaires
    drop_table :questions
  end
end
