require 'clamp'
class LatenessConfig < ActiveRecord::Base
  belongs_to :lateness_config

  def self.unique
    select(column_names - ["id"]).distinct
  end

  def late?(assignment, submission)
    (!submission.ignore_late_penalty) and
      ((submission.created_at || DateTime.current) > assignment.due_date)
  end

  def allow_submission?(assignment, submission)
    fail NotImplementedError, "Each lateness config should implement this"
  end
  
  def late_penalty(assignment, submission)
    fail NotImplementedError, "Each lateness config should implement this"
  end
  
  def days_late(assignment, submission, raw = false)
    return 0 unless raw or late?(assignment, submission)
    due_on = assignment.due_date
    sub_on = submission.created_at || DateTime.current
    late_days = (sub_on.to_time - due_on.to_time) / 1.day
    late_days.ceil
  end

  def penalize(score, assignment, submission)
    # score is [0, 100]
    penalty = late_penalty(assignment, submission) # compute penalty in [0, 100]
    #print "Penalty is #{penalty}\n"
    if self.max_penalty # cap it
      penalty = penalty.clamp(0, self.max_penalty)
    end
    #print "Penalty is now #{penalty}\n"
    #print "Score is #{score}\n"
    ans = (score - penalty).clamp(0, 100)
    #print "Penalized score is #{ans}\n"
    ans
  end

end
