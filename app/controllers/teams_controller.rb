class TeamsController < CoursesController
  # GET /staff/courses/:course_id/teams
  def index
    @course = Course.find(params[:course_id])
    @active_teams = @course.teams.select(&:active?)
    @inactive_teams = @course.teams.reject(&:active?)
  end

  # GET /staff/course/:course_id/teams/new
  def new
    @course = Course.find(params[:course_id])
    @team = Team.new
    @team.course_id = @course.id
    @teams = @course.teams.select(&:active?)
    @others = students_without_active_team
  end

  # POST /staff/course/:course_id/teams
  def create
    @course = Course.find(params[:course_id])
    @team = Team.new(team_params)

    users = params["users"] || []
    @team.users = users.map { |user_id| User.find(user_id.to_i) }

    if @team.save
      redirect_to new_staff_course_team_path(@course),
        notice: 'Team was successfully created.'
    else
      @teams = @course.teams.select(&:active?)
      @others = students_without_active_team
      render :new
    end
  end

  # GET /courses/:course_id/teams/:id
  def show
    @course = Course.find(params[:course_id])
    @team = Team.find(params[:id])

    if @team.users.exclude?(current_user)
      redirect_to(root_path, alert: "You are not a member of that team.")
    end
  end

  def disolve
    @team = Team.find(params[:id])
    @team.update_attribute(:end_date, Date.current)
    redirect_to :back
  end

  private

  def students_without_active_team
    # TODO: Optimize.
    @course.students.reject do |student|
      student.teams.where(course: @course).any? { |t| t.active? }
    end
  end

  def team_params
    params.require(:team).permit(:course_id, :start_date, :end_date)
  end
end
