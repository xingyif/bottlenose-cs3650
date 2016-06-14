class CoursesController < ApplicationController
  before_action :find_course

  # skip_before_action :require_current_user, only: :public
  # before_action :require_course_permission, only: :show

  # GET /courses
  def index
    @courses_by_term = Course.order(:name).group_by(&:term)
  end

  # GET /courses/:id
  def show
    @students = @course.students
    @staff = @course.staff
  end

  # GET /courses/:id/public
  def public
    @course = Course.find(params[:id])

    if current_user
      redirect_to(course_path(@course))
      return
    end

    unless @course.public?
      redirect_to(root_path, notice: 'That course material is not public.')
      return
    end
  end

  protected

  def find_course
    @course = Course.find(params[:course_id] || params[:id])
  end
end
