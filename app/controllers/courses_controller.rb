class CoursesController < ApplicationController
  layout 'course', except: :new

  before_action :load_and_verify_course_registration

  # skip_before_action :require_current_user, only: :public
  # before_action :require_course_permission, only: :show

  # GET /courses
  def index
    @courses_by_term = Course.order(:name).group_by(&:term)

    # We can't use the course layout if we don't have a @course.
    render layout: 'application'
  end

  def new
    @course = Course.new
  end

  def create
    @course = Course.new(course_params)

    unless params[:late_penalty].nil?
      @course.late_options = [
        params[:late_penalty],
        params[:late_repeat],
        params[:late_maximum]
      ].join(',')
    end

    if @course.save
      redirect_to course_path(@course), notice: 'Course was successfully created.'
    else
      render :new
    end
  end

  # GET /courses/:id
  def show
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

  def load_and_verify_course_registration
    # We can't find the course for the action 'courses#index'.
    if controller_name == 'courses' &&
       (action_name == 'index' ||
        action_name == 'new' ||
        action_name == 'create')
      return
    end

    @course = Course.find(params[:course_id] || params[:id])

    require_current_user

    if current_user.site_admin?
      return
    end

    registration = current_user.registration_for(@course)
    if registration.nil?
      msg = "You're not registered for that course."
      redirect_to courses_url, alert: msg
      return
    end
  end

  def course_params
    params[:course].permit(:name, :footer, :late_options, :private, :public,
                           :term_id, :sub_max_size)
  end
end
