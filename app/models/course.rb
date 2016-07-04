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

  def buckets_sorted
    buckets.order(:name)
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

  def total_bucket_weight
    buckets.reduce(0) {|sum, bb| sum + bb.weight }
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
