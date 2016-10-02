class Course < ActiveRecord::Base
  belongs_to :term

  has_many :course_sections, dependent: :destroy
  has_many :registrations, dependent: :destroy
  has_many :users, through: :registrations

  has_many :reg_requests, dependent: :destroy

  has_many :assignments, dependent: :restrict_with_error
  has_many :submissions, through: :assignments
  has_many :teams,       dependent: :destroy

  belongs_to :lateness_config
  validates :lateness_config, presence: true
  validate :valid_lateness_config

  validates :name,    :length      => { :minimum => 2 },
                      :uniqueness  => true

  validates :term_id, presence: true

  def valid_lateness_config
    if !self.lateness_config.nil? && !self.lateness_config.valid?
      self.lateness_config.errors.full_messages.each do |m|
        @errors[:base] << m
      end
    end
  end

  def registered_by?(user, as: nil)
    return false if user.nil?
    registration = Registration.find_by_course_id_and_user_id(self.id, user.id)
    return false if registration.nil?
    if as
      as == registration.role
    else
      registration.role == 'assistant' || registration.role == 'professor'
    end
  end

  def active_registrations
    registrations.where(show_in_lists: true).joins(:user).order("users.last_name", "users.first_name")
  end

  def students
    users.where("registrations.role": RegRequest::roles["student"])
  end

  def students_with_drop_info
    users.where("registrations.role": RegRequest::roles["student"]).select("users.*", "registrations.dropped_date")
  end

  def professors
    users.where("registrations.role": RegRequest::roles["professor"])
  end

  def graders
    users.where("registrations.role": RegRequest::roles["grader"])
  end

  def staff
    users.where("registrations.role <> #{RegRequest::roles["student"]}")
  end

  def first_professor
    professors.first
  end

  def add_registration(username, crn, role = :student)

    # TODO: Check LDAP for user.
    uu = User.find_by(username: username)
    if uu.nil?
      res = Devise::LDAP::Adapter.get_ldap_entry(username)
      if res
        uu = User.create!(username: username,
                          name: res[:displayname][0],
                          last_name: res[:sn][0],
                          first_name: res[:givenname][0],
                          email: res[:mail][0])
      end
    end

    if uu.nil?
      return nil
    end
    section = CourseSection.find_by(crn: crn)
    if section.nil?
      return nil
    end
    # If creating the user fails, this will not create a registration
    # because there is a validation on user.
    registrations.where(user: uu)
                 .first_or_create(user_id: uu.id,
                                  course_id: self.id,
                                  section: section,
                                  role: role,
                                  show_in_lists: role == 'student')
  end

  def score_summary
    assns = self.assignments.where("available < ?", DateTime.current)
    subs = SubsForGrading.where(user: self.students, assignment: assns)
      .joins(:submission)
      .select(:user_id, :assignment_id, :score)
      .to_a
    assn_weights = assns.pluck(:id, :points_available).to_h 
    avail = assn_weights.reduce(0) do |tot, kv| tot + kv[1] end
    remaining = 100.0 - avail
    ans = []
    self.students_with_drop_info.sort_by(&:sort_name).each do |s|
      dropped = s.dropped_date
      used = subs.select{|r| r.user_id == s.id}
      adjust = 0
      min = used.reduce(0.0) do |tot, sub| 
        if (assn_weights[sub.assignment_id] != 0)
          if sub.score.nil?
            adjust += assn_weights[sub.assignment_id]
          end
          tot + ((sub.score || 0) * assn_weights[sub.assignment_id] / 100.0) 
        else
          tot
        end
      end
      cur = (100.0 * min) / (avail - adjust)
      max = min + remaining
      ans.push ({s: s, dropped: dropped, min: min, cur: cur, max: max, pending: adjust})
    end
    ans
  end

  #   as = self.assignments.includes(:subs_for_gradings)

  #   # Partition scores by user.
  #   avails = {}
  #   scores = {}
  #   as.each do |aa|
  #     avails[aa.bucket_id] ||= 0
  #     avails[aa.bucket_id] += aa.points_available

  #     aa.subs_for_gradings.each do |used|
  #       scores[used.user_id] ||= {}
  #       scores[used.user_id][aa.bucket_id] ||= 0
  #       scores[used.user_id][aa.bucket_id] += used.score
  #     end
  #   end

  #   # Calculate percentages.
  #   percents = {}
  #   scores.each do |u_id, bs|
  #     percents[u_id] ||= {}

  #     bs.each do |b_id, score|
  #       if avails[b_id].zero?
  #         percents[u_id][b_id] = 0
  #       else
  #         percents[u_id][b_id] = (100 * score) / avails[b_id]
  #       end
  #     end
  #   end

  #   # Fill in for slackers, calc totals.
  #   totals = {}
  #   users.each do |uu|
  #     percents[uu.id] ||= {}
  #     totals[uu.id] = 0

  #     buckets.each do |bb|
  #       percents[uu.id][bb.id] ||= 0
  #       totals[uu.id] += bb.weight * percents[uu.id][bb.id]
  #     end
  #   end

  #   [percents, totals]
  # end
end
