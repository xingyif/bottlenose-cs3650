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
    prep_sections
    # We can't use the course layout if we don't have a @course.
    render :new, layout: 'application'
  end

  def edit
    prep_sections
  end
  def prep_sections
    @sections = CourseSection.where(course: @course).to_a
    if @sections.count == 0
      @sections = [CourseSection.new(course: @course, instructor: current_user)]
    end
  end

  def create
    unless current_user_site_admin? || current_user_prof_ever?
      redirect_to(root_path, alert: 'Must be an admin or professor to update a course.')
      return
    end

    unless course_section_params.count > 0
      debugger
      flash[:alert] = "Need to create at least one section"
      new
      return
    end
      
    
    @course = Course.new(course_params)

    set_default_lateness_config

    sections = create_sections

    sections.each do |s|
      reg = Registration.find_or_create_by(user: s.instructor,
                                           course: @course,
                                           section: s)
      if reg.nil?
        flash[:alert] = "Error creating course: #{@course.errors.full_messages.join('; ')}"
        new
        return
      else
        reg.update_attributes(role: :professor,
                              show_in_lists: false)
      end
    end
    
    if @course.save
      redirect_to course_path(@course), notice: 'Course was successfully created.'
    else
      flash[:alert] = "Error creating course: #{@course.errors.full_messages.join('; ')}"
      new
      return
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
    if lateness.nil?
      @assignment.errors.add(:lateness, "Lateness parameter is missing")
      return false
    end
      
    type = lateness[:type]
    if type.nil?
      @assignment.errors.add(:lateness, "Lateness type is missing")
      return false
    end
    type = type.split("_")[1]
    
    lateness = lateness[type]
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

  def withdraw
    @course = Course.find(params[:id])
    unless current_user
      redirect_to course_path(@course), alert: 'Must be logged in to withdraw from courses'
      return
    end
    reg = current_user.registration_for(@course)
    if reg.nil?
      redirect_to course_path(@course), alert: "You cannot withdraw from a course you aren't registered for."
      return
    elsif reg.dropped_date
      redirect_to course_path(@course), alert: "You have already withdrawn from this course."
      return
    elsif reg.role == "professor" && @course.professors.count == 1
      redirect_to course_path(@course), alert: "You cannot withdraw from the course: you are the only instructor for it."
      return
    end
    reg.dropped_date = DateTime.now
    reg.show_in_lists = false
    reg.save!
    current_user.disconnect(@course)
    redirect_to root_path, notice: "You have successfully withdrawn from #{@course.name}"
  end

  def gradesheet
    @course = Course.find(params[:id])
    unless current_user_site_admin? || current_user_prof_for?(@course)
      redirect_to course_path(@course), alert: 'Must be an admin or professor to view that information.'
      return
    end
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
      redirect_to courses_url, alert: "You're not registered for that course."
      return
    elsif registration.dropped_date
      redirect_to courses_url, alert: "You've already dropped that course."
      return
    end
  end

  def course_params
    params[:course].permit(:name, :footer, :total_late_days, :private, :public, :course_section,
                           :term_id, :sub_max_size)
  end

  def course_section_params
    params[:course][:course_section].values
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
