require 'csv'
require 'course_spreadsheet'

class CoursesController < ApplicationController
  layout 'course'

  before_filter :require_current_user
  before_action :load_and_verify_course_registration

  def index
    @courses_by_term = Course.order(:name).group_by(&:term)

    # We can't use the course layout if we don't have a @course.
    render layout: 'application'
  end

  def show
  end

  def new
    @course = Course.new

    # We can't use the course layout if we don't have a @course.
    render layout: 'application'
  end

  def edit
  end

  def create
    unless current_user_site_admin?
      redirect_to(root_path, alert: 'Must be an admin to update a course.')
      return
    end

    @course = Course.new(course_params)

    set_default_lateness_config
    
    if @course.save
      redirect_to course_path(@course), notice: 'Course was successfully created.'
    else
      render :new, layout: 'application'
    end
  end

  def update
    unless current_user_site_admin? || current_user_prof_for?(@course)
      redirect_to(root_path, notice: 'Must be an admin or professor to update a course.')
      return
    end

    @course.assign_attributes(course_params)

    set_default_lateness_config

    if @course.save
      redirect_to course_path(@course), notice: 'Course was successfully updated.'
    else
      render :edit, layout: 'application'
    end
  end

  def set_default_lateness_config
    lateness = params[:lateness]
    type = lateness[:type]
    lateness = lateness[type] unless lateness.nil? || type.nil?
    lateness[:type] = type
    if type != "reuse"
      late_config = LatenessConfig.new(lateness.permit(LatenessConfig.attribute_names - ["id"]))
      @course.lateness_config = late_config
      late_config.save
      @course.total_late_days = course_params[:total_late_days]
    end
  end

  def destroy
    unless current_user_site_admin?
      redirect_to(root_path, notice: 'Must be an admin to destroy a course.')
      return
    end

    @course.destroy
    redirect_to courses_path
  end

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


  def gradesheet
    unless current_user_site_admin? || current_user_prof_for?(@course)
      redirect_to :back, notice: 'Must be an admin or professor to update a course.'
      return
    end
    @course = Course.find(params[:id])
    @all_course_info = all_course_info
    respond_to do |format|
      #      format.csv { send_data @all_course_info.to_csv(col_sep: "\t") }
      format.xls
    end
  end

  protected

  def all_course_info
    CourseSpreadsheet.new(@course)
  end
  
  def load_and_verify_course_registration
    # We can't find the course for the action 'courses#index'.
    if controller_name == 'courses' &&
       (action_name == 'index' ||
        action_name == 'new' ||
        action_name == 'create')
      return
    end

    @course = Course.find(params[:course_id] || params[:id])

    if current_user_site_admin?
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
    params[:course].permit(:name, :footer, :total_late_days, :private, :public,
                           :term_id, :sub_max_size)
  end


  protected
  def plural(n, sing, pl = nil)
    if n == 1
      "1 #{sing}"
    elsif pl
      "#{n} #{pl}"
    else
      "#{n} #{sing}s"
    end
  end
end
