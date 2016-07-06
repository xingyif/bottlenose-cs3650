class JunitGrader < GraderConfig
  def grade(assignment, sub)
    g = self.grader_for sub
    g.score = 0
    g.updated_at = DateTime.now
    g.available = true
    g.save!
    return 0
  end
end
