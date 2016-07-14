class LatenessConfig < ActiveRecord::Base
  belongs_to :lateness_config

  def self.unique
    select(column_names - ["id"]).distinct
  end

  def late?(assignment, submission)
    (submission.created_at || DateTime.current) > assignment.due_date
  end

  def allow_submission?(assignment, submission)
    fail NotImplementedError, "Each lateness config should implement this"
  end
  
  def late_penalty(assignment, submission)
    fail NotImplementedError, "Each lateness config should implement this"
  end
  
  def days_late(assignment, submission)
    return 0 unless late?(assignment, submission)
    due_on = assignment.due_date
    sub_on = submission.created_at || DateTime.current
    late_days = (sub_on.to_time - due_on.to_time) / 1.day
    late_days.ceil
  end

  def penalize(score, assignment, submission)
    penalty = late_penalty(assignment, submission) # compute penalty in [0, 1.0]
    if self.max_penalty # cap it
      penalty = [self.max_penalty, penalty].min
    end
    [100, [0, score - penalty].max].min
  end

end
