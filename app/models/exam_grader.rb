require 'clamp'
class ExamGrader < GraderConfig
  def autograde!(assignment, sub)
    g = self.grader_for sub
    
    g.out_of = self.avail_score
    
    g.updated_at = DateTime.now
    g.available = false
    g.save!

    return nil
  end

  def to_s
    "Question grading"
  end

  def expect_num_questions(num)
    @num_questions = num
  end

  def upload_file=(data)
    unless data.nil?
      errors[:base] << "You cannot submit a file for exams."
      return
    end
  end
  
  protected
  
  def do_grading(assignment, sub)
    g = self.grader_for sub
    comments = InlineComment.where(submission: sub, grader: g, suppressed: false)
    score = comments.pluck(:weight).reduce(0) do |sum, w| sum + w end
    
    g.out_of = self.avail_score
    g.score = [0, score].max # can get extra credit above max score
    
    g.updated_at = DateTime.now
    g.available = (comments.count == @num_questions)
    g.save!

    return g.score
  end
end
