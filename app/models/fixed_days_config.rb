class FixedDaysConfig < LatenessConfig
  def allow_submission?(assignment, submission)
    late_days = super.days_late(assignment, submission)
    return false if late_days > self.days_per_assignment
    max_late_days = assignment.course.total_late_days
    return true if max_late_days.nil?
    submission.users.any? do |u|
      (u.late_days_used + late_days > max_late_days)
    end
  end

  def late_penalty(assignment, submission)
    0
  end
end
