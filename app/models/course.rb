class Course < ActiveRecord::Base
  belongs_to :term

  has_many :registrations, dependent: :destroy
  has_many :users, through: :registrations

  has_many :reg_requests, dependent: :destroy

  has_many :assignments, dependent: :restrict_with_error
  has_many :submissions, through: :assignments
  has_many :teams,       dependent: :destroy

  validates :name,    :length      => { :minimum => 2 },
                      :uniqueness  => true
  validates :late_options, :format => { :with => /\A\d+,\d+,\d+\z/ }

  validates :term_id, presence: true

  def late_opts
    # pen, del, max
    os = late_options.split(",")
    os.map {|oo| oo.to_i}
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
    registrations.where(:show_in_lists?).order(:last_name, :first_name)
  end

  def students
    users.where("registrations.role": RegRequest::roles["student"])
  end

  def professors
    users.where("registrations.role": RegRequest::roles["professor"])
  end

  def staff
    users.where("registrations.role <> #{RegRequest::roles["student"]}")
  end

  def first_professor
    professors.first
  end

  def add_registration(email, role = :student)
    email.downcase!

    name, _ = email.split('@')
    name.downcase!

    # TODO: Check LDAP for user.
    uu = User.where(email: email)
             .first_or_create(name: name)

    # If creating the user fails, this will not create a registration
    # because there is a validation on user.
    registrations.where(user: uu)
                 .first_or_create(user_id: uu.id,
                                  course_id: self.id,
                                  role: role,
                                  show_in_lists: role == 'student')
  end

  def score_summary
    subs = SubsForGrading.where(user: self.students)
      .joins(:submission).select(:user_id, :assignment_id, :score).to_a
    assn_weights = self.assignments.pluck(:id, :points_available).to_h 
    avail = assn_weights.reduce(0) do |tot, kv| tot + kv[1] end
    remaining = 100.0 - avail
    ans = []
    self.students.sort_by(&:sort_name).each do |s|
      used = subs.select{|r| r.user_id == s.id}
      min = used.reduce(0.0) do |tot, sub| 
        if (assn_weights[sub.assignment_id] != 0)
          tot + (sub.score * assn_weights[sub.assignment_id] / 100.0) 
        else
          tot
        end
      end
      cur = (100.0 * min) / avail
      max = min + remaining
      ans.push ({s: s, min: min, cur: cur, max: max})
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
