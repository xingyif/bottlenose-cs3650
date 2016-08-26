class Question < ActiveRecord::Base
  enum question_type: [:multiple_choice, :yes_no, :true_false, :numeric, :free_text, :code_reference]
  
  belongs_to :questionnaire
  validates :questionnaire, presence: true
end

class MultipleChoiceQuestion < Question
  def readable_type
    "Multiple choice"
  end
end
class YesNoQuestion < Question
  def readable_type
    "Yes/No"
  end
end
class TrueFalseQuestion < Question
  def readable_type
    "True/False"
  end
end
class NumericQuestion < Question
  def readable_type
    "Numeric"
  end
end
class FreeTextQuestion < Question
  def readable_type
    "Free response"
  end
end
class CodeReferenceQuestion < Question
  def readable_type
    "Code reference"
  end
end
