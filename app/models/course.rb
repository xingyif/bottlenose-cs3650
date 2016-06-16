class Course < ActiveRecord::Base
  belongs_to :term

  has_many :registrations, dependent: :destroy
  has_many :users, through: :registrations

  has_many :reg_requests, dependent: :destroy

  has_many :buckets,     dependent: :destroy
  has_many :assignments, dependent: :restrict_with_error
  has_many :teams,       dependent: :destroy

  validates :name,    :length      => { :minimum => 2 },
                      :uniqueness  => true
  validates :late_options, :format => { :with => /\A\d+,\d+,\d+\z/ }

  validates :term_id, presence: true

  after_create do
    Bucket.create!(name: "Assignments", weight: 1.0, course: self)
  end

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

  def regs_sorted
    registrations.includes(:user).to_a.sort_by do |reg|
      reg.user.invert_name.downcase
    end
  end

  def buckets_sorted
    buckets.order(:name)
  end

  def staff_registrations
    regs_sorted.find_all { |reg| reg.role == 'professor' || reg.role == 'staff' }
  end

  def professor_registrations
    regs_sorted.find_all { |reg| reg.role == 'professor' }
  end

  # TODO: Need to rethink roles. Should be professor, assistant, and student.

  def student_registrations
    regs_sorted.find_all { |reg| reg.role == 'student' }
  end

  def active_registrations
    regs_sorted.find_all { |reg| reg.show_in_lists? }
  end

  # TODO: Make these kinds of things return relations, not arrays. This
  # will allow code like that found in teams#index to perform optimized
  # joins.
  def students
    student_registrations.map {|reg| reg.user}
  end

  def staff
    staff_registrations.map {|reg| reg.user}
  end

  def first_professor
    professors.first
  end

  def total_bucket_weight
    buckets.reduce(0) {|sum, bb| sum + bb.weight }
  end

  def add_registration(email, teacher = false)
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
                                  teacher: teacher,
                                  show_in_lists: !teacher)
  end

  def score_summary
    as = self.assignments.includes(:best_subs)

    # Partition scores by user.
    avails = {}
    scores = {}
    as.each do |aa|
      avails[aa.bucket_id] ||= 0
      avails[aa.bucket_id] += aa.points_available

      aa.best_subs.each do |bs|
        scores[bs.user_id] ||= {}
        scores[bs.user_id][aa.bucket_id] ||= 0
        scores[bs.user_id][aa.bucket_id] += bs.score
      end
    end

    # Calculate percentages.
    percents = {}
    scores.each do |u_id, bs|
      percents[u_id] ||= {}

      bs.each do |b_id, score|
        if avails[b_id].zero?
          percents[u_id][b_id] = 0
        else
          percents[u_id][b_id] = (100 * score) / avails[b_id]
        end
      end
    end

    # Fill in for slackers, calc totals.
    totals = {}
    users.each do |uu|
      percents[uu.id] ||= {}
      totals[uu.id] = 0

      buckets.each do |bb|
        percents[uu.id][bb.id] ||= 0
        totals[uu.id] += bb.weight * percents[uu.id][bb.id]
      end
    end

    [percents, totals]
  end
end
