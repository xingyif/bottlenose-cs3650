class AssignmentsController < ApplicationController
  before_action :require_course_permission

  # GET /courses/:course_id/assignments/:id
  def show
    @assignment = @course.assignments.find(params[:id])
    @submissions = @assignment.submissions.where(user_id: current_user.id)
    @team = current_user.active_team(@course)
  end
end
