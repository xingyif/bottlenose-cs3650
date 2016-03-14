class Staff::TeamsController < Staff::BaseController
  # GET /staff/courses/:course_id/teams
  def index
    @course = Course.find(params[:course_id])
    @active_teams = @course.teams.select(&:active?)
    @inactive_teams = @course.teams.reject(&:active?)
  end
end
