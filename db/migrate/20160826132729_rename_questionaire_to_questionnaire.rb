class RenameQuestionaireToQuestionnaire < ActiveRecord::Migration
  def change
    rename_table :questionaires, :questionnaires
    rename_column :questions, :questionaire_id, :questionnaire_id
  end
end
