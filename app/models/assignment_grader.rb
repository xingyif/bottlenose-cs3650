class AssignmentGrader < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :grader_config
end
