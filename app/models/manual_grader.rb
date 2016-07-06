class ManualGrader < GraderConfig
  def grade(assignment, sub)
    g = self.grader_for sub
    g.score = rand(self.avail_score)
    g.updated_at = DateTime.now
    g.available = true
    g.save!

    g.score
  end
end
