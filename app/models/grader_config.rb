class GraderConfig < ActiveRecord::Base
  belongs_to :submission
  belongs_to :grader_config

  def grade(assignment, submission)
    fail NotImplementedError, "Each grader should implement this"
  end

  def autograde?
    false
  end

  def grader_exists_for(sub)
    !Grader.find_by(grader_config_id: self.id, submission_id: sub.id).nil?
  end
  
  protected
  
  def grader_for(sub)
    g = Grader.find_or_create_by(grader_config_id: self.id, submission_id: sub.id)
    if g.new_record?
      g.out_of = self.avail_score
    end
    g
  end
end
