class CoursesController < ApplicationController
  skip_before_action :require_logged_in_user, only: :public

  def index
    @courses_by_term = Course.order(:name).group_by(&:term)
  end

  def show
    @course = Course.find(params[:id])

    unless current_user.registration_for(@course)
      redirect_to courses_path, alert: "You are not registered for that course"
    end
  end

  # TODO
  def public
    unless current_user.nil?
      redirect_to @course
    end

    unless @course.public?
      redirect_to root_path, notice: 'That course material is not public'
    end
  end
end
