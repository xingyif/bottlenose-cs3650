class GraderConfig < ActiveRecord::Base
  belongs_to :submission
  belongs_to :grader_config

  def grade(assignment, submission)
    ans = do_grading(assignment, submission)
    submission.compute_grade! if submission.graders.pluck(:available).all?
    ans
  end

  def autograde?
    false
  end

  def autograde!(assignment, submission)
    grade(assignment, submission)
  end
  
  def grader_exists_for(sub)
    !Grader.find_by(grader_config_id: self.id, submission_id: sub.id).nil?
  end
  
  protected

  def do_grading(assignment, submission)
    fail NotImplementedError, "Each grader should implement this"
  end
  
  def grader_for(sub)
    g = Grader.find_or_create_by(grader_config_id: self.id, submission_id: sub.id)
    if g.new_record?
      g.out_of = self.avail_score
    end
    g
  end
end
