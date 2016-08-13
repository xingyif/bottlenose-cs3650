class Team < ActiveRecord::Base
  belongs_to :course
  has_many   :team_users, dependent: :destroy
  has_many   :users, through: :team_users
  has_many   :submissions

  validates :course_id,  presence: true
  validates :start_date, presence: true
  validates :users, presence: true
  validate :end_not_before_start
  validate :all_enrolled

  def to_s
    "Team #{self.id} - #{self.member_names}"
  end

  def member_names
    users.sort_by(&:sort_name).map(&:name).join(", ")
  end

  # If the end date of a team is not set (nil) then this team does not
  # have an end date, and as such will always be active. Start and end
  # dates form a half open interval. This means that the team with a
  # start date of 2016-02-05 and end date of 2016-02-10 was a team
  # active for only 5 days, and specifically not active on the 10th of
  # February.
  def active?
    if self.end_date
      Date.current.between?(self.start_date, self.end_date - 1)
    else
      true
    end
  end

  def disolve(as_of)
    return unless self.end_date.nil?
    self.update_attribute(:end_date, as_of)
    self.submissions.joins(:assignment).where('due_date >= ?', as_of)
      .update_all(stale_team: true)
  end

  private

  def all_enrolled
    not_enrolled = users.find {|u| !u.course_student?(course)}
    if not_enrolled
      errors[:base] << "Not all students are enrolled in this course: " + not_enrolled.to_a.to_s
    end
  end

  def end_not_before_start
    return if end_date.blank?

    if end_date < start_date
      errors.add(:end_date, "must be not be before the start date")
    end
  end
end
