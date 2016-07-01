require 'securerandom'

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :ldap_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable
  has_many :registrations
  has_many :courses, through: :registrations, :dependent => :restrict_with_error

  has_many :submissions,  dependent: :restrict_with_error
  has_many :reg_requests, dependent: :destroy

  has_many :team_users, dependent: :destroy
  has_many :teams, through: :team_users, dependent: :destroy

  validates :email, :format => { :with => /\@.*\./ }

  validates :email, uniqueness: true
  validates :name,  length: { in: 2..30 }

  # Different people with the same name are fine.
  # If someone uses two emails, they get two accounts. So sad.
  #validates :name,  :uniqueness => true

  def ldap_before_save
    self.name = Devise::LDAP::Adapter.get_ldap_param(self.email, "displayname").first
  end

  before_validation do
    unless self.email.nil?
      self.email = self.email.downcase
      self.email = self.email.strip
      self.email.sub!(/\W$/, '')
    end
  end

  def to_s
    self.email
  end

  def course_staff?(course)
    course_professor?(course) || course_assistant?(course)
  end

  def professor_ever?
    courses.any? {|c| self.course_professor?(c) }
  end

  def course_professor?(course)
    course.registered_by?(self, as: 'professor')
  end

  def course_assistant?(course)
    course.registered_by?(self, as: 'assistant')
  end

  def course_student?(course)
    course.registered_by?(self, as: 'student')
  end

  def registration_for(course)
    Registration.find_by_user_id_and_course_id(self.id, course.id)
  end

  def invert_name
    name.split(/\s+/).rotate(-1).join(' ')
  end

  def surname
    invert_name.split(/\s+/).first
  end

  def dir_name
    invert_name.gsub(/\W/, '_')
  end

  def reasonable_name?
    name =~ /\s/ && name.downcase != name
  end

  def active_team(course)
    warn "[DEPRECATED] `active_team` use `active_team_for` instead."
    active_team_for(course)
  end

  def active_team_for(course)
    @active_team ||= teams_for(course).select(&:active?).first
  end

  def teams_for(course)
    @teams ||= teams.where(course: course)
  end
end
