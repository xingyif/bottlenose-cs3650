class TeamsController < CoursesController
  # GET /courses/:course_id/teams/:id
  def show
    @course = Course.find(params[:course_id])
    @team = Team.find(params[:id])

    if @team.users.exclude?(current_user)
      redirect_to(root_path, alert: "You are not a member of that team.")
    end
  end
end
