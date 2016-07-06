require 'securerandom'
require 'audit'

class Submission < ActiveRecord::Base
  belongs_to :assignment
  belongs_to :user
  belongs_to :team
  belongs_to :upload
  belongs_to :comments_upload, class_name: "Upload"
  has_many :subs_for_gradings, dependent: :destroy
  has_many :graders
  has_many :user_submissions, dependent: :destroy
  has_many :users, through: :user_submissions

  validates :assignment_id, :presence => true

  validate :has_team_or_user
  validate :user_is_registered_for_course
  validate :submitted_file_or_manual_grade
  validate :file_below_max_size

  delegate :course,    :to => :assignment
  delegate :file_name, :to => :upload, :allow_nil => true

  before_destroy :cleanup!
  after_save :add_user_submissions!
  after_save :update_used_subs!

  def add_user_submissions!
    if team
      team.users.each do |u|
        UserSubmission.create!(user: u, submission: self)
      end
    elsif user
      UserSubmission.create!(user: user, submission: self)
    end
  end

  def set_used_sub!
    if team
      team.users.each do |u|
        used = SubsForGrading.find_or_initialize_by(user_id: u.id, assignment_id: assignment.id)
        used.submission_id = self.id
        used.score = self.score
        used.save!
      end
    else
      used = SubsForGrading.find_or_initialize_by(user_id: user.id, assignment_id: assignment_id)
      used.submission_id = self.id
      used.score = self.score
      used.save!
    end
  end

  def update_used_subs!
    SubsForGrading.where(submission_id: self.id).each do |s| 
      s.score = self.score
      s.save!
    end
  end

  def name
    "#{user.name} @ #{created_at}"
  end

  def upload_file=(data)
    return if data.nil?

    unless upload_id.nil?
      raise Exception.new("Attempt to replace submission upload.")
    end

    self.upload_size = data.size
    @upload_data = data
  end

  def save_upload
    if @upload_data.nil?
      return
    end

    data = @upload_data

    if data.size > course.sub_max_size.megabytes
      return
    end

    up = Upload.new
    up.user_id = user.id
    up.store_meta!({
      type:       "Submission",
      user:       "#{user.name} (#{user.id})",
      course:     "#{course.name} (#{course.id})",
      assignment: "#{assignment.name} (#{assignment.id})",
      date:       Time.now.strftime("%Y/%b/%d %H:%M:%S %Z")
    })
    up.store_upload!(data)
    if up.save
      self.upload_id = up.id
      
      Audit.log("Sub #{id}: New submission upload by #{user.name} " +
                "(#{user.id}) with key #{up.secret_key}")
    else
      false
    end
  end

  def comments_upload_file=(data)
    return if data.nil?

    unless comments_upload_id.nil?
      comments_upload.destroy
    end

    up = Upload.new
    up.user_id = user.id
    up.store_meta!({
      type:       "Submission Comments",
      user:       "Some teacher for #{user.name} (#{user.id})",
      course:     "#{course.name} (#{course.id})",
      assignment: "#{assignment.name} (#{assignment.id})",
      date:       Time.now.strftime("%Y/%b/%d %H:%M:%S %Z")
    })
    up.store_upload!(data)
    up.save!

    self.comments_upload_id = up.id
    self.save!
  end

  def file_path
    if upload_id.nil?
      ""
    else
      upload.path
    end
  end

  def file_full_path
    if upload_id.nil?
      ""
    else
      upload.full_path
    end
  end

  def late?
    return false if new_record?
    created_at.to_date > assignment.due_date
  end

  def days_late
    return 0 unless late?
    due_on = assignment.due_date.to_time
    sub_on = created_at
    late_days = (sub_on - due_on) / 1.day
    late_days.floor
  end

  def late_penalty
    # Returns multiplier for post-penalty score.
    return 0.0 unless late?
    return 0.0 if ignore_late_penalty?

    (pen, del, max) = course.late_opts

    percent_off = (days_late / del) * pen
    percent_off = max if percent_off > max

    percent_off / 100.0
  end

  def late_mult
    1.0 - late_penalty
  end

  def grade!
    ### A Submission's score is recorded as a percentage
    score = 0.0
    max_score = 0.0
    log = ""
    assignment.grader_configs.each do |c|
      begin
        res = c.grade(assignment, self)
        max_score += c.avail_score
        log += "#{c.type} => #{res}, "
        unless res.nil?
          score += res
        end
      rescue NotImplementedError
      end
    end
    self.score = (100.0 * score) / max_score
    log += "Final score: #{self.score}%"
    # TODO: Lateness
    Audit.log("Grading submission at #{DateTime.current}, grades are #{log}\n")
    self.save!

    # root = Rails.root.to_s
    # system(%Q{(cd "#{root}" && script/grade-submission #{self.id})&})
  end

  def cleanup!
    upload.cleanup! unless upload.nil?
  end

  def visible_to?(user)
    user.course_staff?(course) ||
      UserSubmission.exists?(user: user, submission: self)
  end

  private

  def user_is_registered_for_course
    if user && !user.courses.any?{|cc| cc.id == course.id }
      errors[:base] << "Not registered for this course :" + user.name
    end
    if team && !team.users.all?{|u| u.courses.any?{|cc| cc.id == course.id } }
      errors[:base] << "Not registered for this course :" + team.users.map{|u| u.name}.to_s
    end
  end

  def submitted_file_or_manual_grade
    if upload_id.nil? && teacher_score.nil?
      errors[:base] << "You need to submit a file."
    end
  end

  def file_below_max_size
    msz = course.sub_max_size
    if upload_size > msz.megabytes
      errors[:base] << "Upload exceeds max size (#{upload_size} > #{msz} MB)."
    end
  end

  def has_team_or_user
    if assignment.team_subs?
      if team.nil?
        errors[:base] << "Assignment requires team subs. No team set."
      end
    else
      if user.nil?      
        errors[:base] << "Assignment requires individual subs. No user set."
      elsif team
        errors[:base] << "Assignment requires individual subs. Team should not be set."
      end
    end
  end
end
