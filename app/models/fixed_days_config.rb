class FixedDaysConfig < LatenessConfig
  validates :days_per_assignment, :numericality => true

  def allow_submission?(assignment, submission)
    late_days = days_late(assignment, submission)
    return false if late_days > self.days_per_assignment
    max_late_days = assignment.course.total_late_days
    return true if max_late_days.nil?
    submission.users.all? do |u|
      (u.late_days_used + late_days <= max_late_days)
    end
  end

  def late_penalty(assignment, submission)
    0
  end

  def to_s
    "Allow #{self.days_per_assignment} days per assignment; limit to course's maximum total late days; everyone on team must have sufficient late days remaining"
  end

  def ==(other)
    if other.instance_of?(FixedDaysConfig)
      self.days_per_assignment == other.days_per_assignment
    else
      false
    end
  end
end
