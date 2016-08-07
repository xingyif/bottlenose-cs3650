class ManualGrader < GraderConfig
  def grade(assignment, sub)
    g = self.grader_for sub
    # HACK
    g.score = rand(self.avail_score)
    g.out_of = self.avail_score
    
    g.updated_at = DateTime.now
    g.available = false
    g.save!

    return self.avail_score * (g.score.to_f / g.out_of.to_f)
  end
end
