require 'clamp'
class QuestionsGrader < GraderConfig
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

  
  protected
  
  def do_grading(assignment, sub)
    g = self.grader_for sub
    comments = InlineComment.where(submission: sub, grader: g, suppressed: false)
    deductions = comments.pluck(:weight).reduce(0) do |sum, w| sum + w end
    
    g.out_of = self.avail_score
    g.score = (self.avail_score - deductions).clamp(0, self.avail_score)
    
    g.updated_at = DateTime.now
    g.available = false
    g.save!

    return g.score
  end
end
