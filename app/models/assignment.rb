require 'securerandom'
require 'audit'

class Assignment < ActiveRecord::Base
  def self.inheritance_column
    nil # TODO: For now; I might want to subclass this after all
  end
  enum assignment_kind: [:files, :questions]
  enum question_kind: [:yes_no, :true_false, :multiple_choice, :numeric, :text]
  
  belongs_to :blame, :class_name => "User", :foreign_key => "blame_id"

  belongs_to :course

  belongs_to :lateness_config

  belongs_to :related_assignment, :class_name => "Assignment", :foreign_key => "related_assignment_id"
  
  has_many :submissions, :dependent => :restrict_with_error
  has_many :subs_for_gradings, :dependent => :destroy

  has_many :assignment_graders, :dependent => :destroy
  has_many :grader_configs, through: :assignment_graders

  validates :name,      :uniqueness => { :scope => :course_id }
  validates :name,      :presence => true
  validates :course_id, :presence => true
  validates :due_date,  :presence => true
  validates :available, :presence => true
  validates :blame_id,  :presence => true
  validates :points_available, :numericality => true
  validates :lateness_config, :presence => true
  validate :valid_lateness_config

  def valid_lateness_config
    if !self.lateness_config.valid?
      self.lateness_config.errors.full_messages.each do |m|
        @errors[:base] << m
      end
    end
  end

  def sub_late?(sub)
    self.lateness_config.late?(self, sub)
  end

  def sub_days_late(sub)
    self.lateness_config.days_late(self, sub)
  end
  
  def sub_late_penalty(sub)
    self.lateness_config.late_penalty(self, sub)
  end

  def sub_allow_submission?(sub)
    self.lateness_config.allow_submission?(self, sub)
  end

  def rate_limit?(sub)
    if self.max_attempts.to_i > 0 and self.submissions.count >= self.max_attempts.to_i
      "permanent"
    elsif self.rate_per_hour.to_i > 0 and
         self.submission.where('created_at >= ?', DateTime.now - 1.hour).count > self.rate_per_hour.to_i
      "temporary"
    else
      false
    end
  end

  def assignment_upload
    Upload.find_by_id(assignment_upload_id)
  end

  def assignment_file
    if assignment_upload_id.nil?
      ""
    else
      assignment_upload.file_name
    end
  end

  def assignment_file_name
    assignment_file
  end

  def assignment_full_path
    assignment_upload.submission_path
  end

  def assignment_file_path
    if assignment_upload_id.nil?
      ""
    else
      assignment_upload.path
    end
  end
  def assignment_file=(data)
    @assignment_file_data = data
  end

  def save_uploads!
    user = User.find(blame_id)

    if @assignment_file_data.nil?
      debugger
    else
      unless assignment_upload_id.nil?
        Audit.log("Assn #{id}: Orphaning assignment upload " +
                  "#{assignment_upload_id} (#{assignment_upload.secret_key})")
      end

      up = Upload.new
      up.user_id = user.id
      up.store_upload!(@assignment_file_data, {
        type:       "Assignment File",
        user:       "#{user.name} (#{user.id})",
        course:     "#{course.name} (#{course.id})",
        date:       Time.now.strftime("%Y/%b/%d %H:%M:%S %Z")
      })
      up.save!

      self.assignment_upload_id = up.id
      self.save!

      Audit.log("Assn #{id}: New assignment file upload by #{user.name} " +
                "(#{user.id}) with key #{up.secret_key}")
    end
  end

  def submissions_for(user)
    if team_subs?
      # This version of the query is slower, according to SQL explain
      # user.submissions.where(assignment_id: self.id).order(created_at: :desc)
      Submission.
        joins(:team).
        joins("JOIN team_users ON team_users.team_id = teams.id").
        where("team_users.user_id = ? and submissions.assignment_id = ?", user.id, self.id).
        order(created_at: :desc)
    else
      submissions.where(user_id: user.id).order(created_at: :desc)
    end
  end

  def used_submissions
    # Only those unique submissions that are marked as used-for-grading for this assignment
    all_used_subs.distinct
  end
  def all_used_subs
    Submission.joins(:subs_for_gradings).where(assignment_id: self.id)
  end

  def used_sub_for(user)
    ans = SubsForGrading.find_by(user_id: user.id, assignment_id: self.id)
    if ans.nil?
      ans
    else
      ans.submission
    end
  end

  def main_submissions
    regs = course.active_registrations
    subs = regs.map do |sreg|
      used_sub_for(sreg.user)
    end
  end

  def questions
    if self.type == "questions"
      YAML.load(File.read(self.assignment_upload.submission_path))
    else
      nil
    end
  end
end
