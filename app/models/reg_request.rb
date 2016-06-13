class RegRequest < ActiveRecord::Base
  enum role: [:student, :staff, :professor]

  validates_presence_of :course_id, :user_id

  belongs_to :course
  belongs_to :user

  validates :user_id, :uniqueness => { :scope => :course_id }

  delegate :name, :email, to: :user

  def registered?
    course.users.any? {|uu| uu.id == user_id }
  end

  # Accept this registration, adding a new Registration for
  # the user to the requested course.
  def accept!
    Registration.create!(course: self.course,
                         user: self.user,
                         teacher: false,
                         show_in_lists: true)
    # It's safe to call destroy here since `create!` will raise an
    # exception if it fails.
    destroy
  end

  # Reject this registration request, simply deleting it without
  # adding the user to the requested course.
  def reject!
    destroy
  end
end
