class TeamsController < CoursesController
  # GET /staff/courses/:course_id/teams
  def index
    @course = Course.find(params[:course_id])
    if current_user_site_admin? || current_user_staff_for?(@course)
      @active_teams = @course.teams.select(&:active?)
      @inactive_teams = @course.teams.reject(&:active?)
    else
      @active_teams = current_user.teams.select(&:active?)
      @inactive_teams = current_user.teams.reject(&:active?)
    end
  end

  # GET /staff/course/:course_id/teams/new
  def new
    unless current_user_site_admin? || current_user_staff_for?(@course)
      redirect_to course_teams_path, alert: "Must be an admin or staff."
      return
    end
    @course = Course.find(params[:course_id])
    @team = Team.new
    @team.course_id = @course.id
    @teams = @course.teams.select(&:active?)
    @others = students_without_active_team
  end

  # POST /staff/course/:course_id/teams
  def create
    unless current_user_site_admin? || current_user_staff_for?(@course)
      redirect_to course_teams_path, alert: "Must be an admin or staff."
      return
    end

    @course = Course.find(params[:course_id])
    @team = Team.new(team_params)

    users = params["users"] || []
    @team.users = users.map { |user_id| User.find(user_id.to_i) }

    if @team.save
      redirect_to new_course_team_path(@course),
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
    unless current_user_site_admin? || current_user_staff_for?(@course)
      redirect_to root_path, alert: "Must be an admin or staff."
      return
    end

    @team = Team.find(params[:id])
    @team.disolve(Date.current)
    redirect_to :back
  end


  def disolve_all
    unless current_user_site_admin? || current_user_staff_for?(@course)
      redirect_to root_path, alert: "Must be an admin or staff."
      return
    end

    teams = Team.where(course: @course, end_date: nil)
    teams.each do |t| t.disolve(Date.current) end
    redirect_to :back, notice: "#{plural(teams.count, 'team')} disolved"
  end

  def randomize
    unless current_user_site_admin? || current_user_staff_for?(@course)
      redirect_to root_path, alert: "Must be an admin or staff."
      return
    end

    count = 0
    students_without_active_team.to_a.shuffle.each_slice(params[:random][:size].to_i).each do |t|
      @team = Team.new(course: @course, start_date: params[:random][:start_date], end_date: params[:random][:end_date])
      @team.users = t

      if @team.save
        count += 1
      end
    end
    redirect_to :back, notice: "#{plural(count, 'random team')} created"
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
