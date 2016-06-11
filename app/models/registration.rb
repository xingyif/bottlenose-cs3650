class Registration < ActiveRecord::Base
  # The role for a regestration is a way for Bottlenose to allow a single user
  # to be a staff role for one course, while being a student in another.
  # Professors have extra privileges over staff.
  enum role: [:student, :staff, :professor]

  # A regestration is join model between a user and a course.
  belongs_to :user
  belongs_to :course

  # Only one regestration per user per course is allowed.
  validates :user_id, uniqueness: { scope: :course_id }

  # TODO <refactor>: Delete, this looks unused, if only we have a compiler...
  def self.get(c_id, u_id)
    Registration.find_by_course_id_and_user_id(c_id, u_id)
  end

  # Return the submissions to the course the user is registered for.
  def submissions
    user.submissions.select { |s| s.course == course }
  end

  # TODO <refactor>: Is this used?
  def best_subs
    Assignment.where(course_id: course_id).map do |aa|
      aa.main_submission_for(user)
    end.find_all do |ss|
      !ss.nil?
    end
  end

  # Return the total score for the student in the course. This value is
  # meaningless for staff and professors. The value is a percent.
  def total_score
    total = 0.0

    course.buckets.each do |bb|
      ratio = bb.points_ratio(user)
      total += ratio * bb.weight
    end

    (total * 100.0).round
  end
end
