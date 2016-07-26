class RegRequest < ActiveRecord::Base
  enum role: [:student, :grader, :assistant, :professor]

  validates_presence_of :course_id, :user_id

  belongs_to :course
  belongs_to :user

  validates :user_id, :uniqueness => { :scope => :course_id }

  delegate :name, :email, to: :user
end
