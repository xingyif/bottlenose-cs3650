class AssignmentsController < CoursesController
  # before_action :require_course_permission

  # GET /courses/:course_id/assignments/:id
  def show
    @assignment = Assignment.find(params[:id])

    if current_user.site_admin? || current_user.registration_for(@course).staff?
      @submissions = @assignment.submissions.where(user_id: current_user.id)
    else
      @submissions = @assignment.submissions
    end
  end
end
