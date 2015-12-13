class SubmissionsController < ApplicationController
  before_action :find_submission_and_assignment
  before_action :setup_breadcrumbs
  
  before_filter :require_teacher, :except => [:new, :create, :show]
  before_filter :require_student

  def index
    @submissions = @assignment.submissions
  end

  def show
    add_breadcrumb @submission.name

    unless @logged_in_user.course_admin?(@course) or 
        @logged_in_user.id == @submission.user_id
      show_error "That's not your submission."
      redirect_to @assignment
    end
  end

  def new
    add_breadcrumb "New Submission"

    @submission = Submission.new
    @submission.assignment_id = @assignment.id
    @submission.user_id = @logged_in_user.id
    
    @team = @logged_in_user.active_team(@course)
    @submission.team = @team
  end

  def edit
    add_breadcrumb @submission.name, @submission
    add_breadcrumb "Grading"
    
    @team = @logged_in_user.active_team(@course)
  end

  def create
    @submission = Submission.new(submission_params)
    @submission.assignment_id = @assignment.id

    @row_user = User.find_by_id(params[:row_user_id])

    if @logged_in_user.course_admin?(@course)
      @submission.user ||= @logged_in_user
      @submission.team ||= @submission.user.active_team(@course)
    else
      @submission.user = @logged_in_user
      @submission.team = @submission.user.active_team(@course)
      @submission.ignore_late_penalty = false
    end
      
    @team = @submission.team
    @submission.save_upload!

    if @submission.save
      @submission.grade!
      respond_to do |format|
        format.html do
          redirect_to @submission, notice: 'Submission was successfully created.'
        end
        format.js   { render action: "show" }
      end
    else
      @submission.cleanup!
      respond_to do |format|
        format.html { render action: "new"  }
        format.js   { render action: "show" }
      end
    end
  end

  def update
    @row_user = User.find_by_id(params[:row_user_id])

    if @submission.update_attributes(submission_params)
      respond_to do |format|
        format.html { redirect_to @submission, notice: 'Submission was successfully updated.' }
        format.js   { render action: "show" }
      end
    else
      respond_to do |format|
        format.html { render action: "edit" }
        format.js   { render action: "show" }
      end
    end
  end

  def destroy
    @submission = Submission.find(params[:id])
    redirect_to @submission, :error => "Submission#destroy disabled."

    # @submission.destroy
    # redirect_to assignment_submissions_url(@assignment)
  end

  def manual_grade
    @submission = Submission.new
    @submission.assignment_id = @assignment.id
    @submission.ignore_late_penalty = true

    @users = @course.users
  end

  private

  def find_submission_and_assignment
    if params[:id]
      @submission = Submission.find(params[:id])
      @assignment = @submission.assignment
    end

    if params[:assignment_id]
      @assignment = Assignment.find(params[:assignment_id])
    end

    @course = @assignment.course
  end

  def setup_breadcrumbs
    add_root_breadcrumb
    add_breadcrumb "Courses", courses_path
    add_breadcrumb @course.name, @course

    unless (@assignment.nil? || @assignment.bucket.nil?)
      add_breadcrumb @assignment.bucket.name, @course
      add_breadcrumb @assignment.name, @assignment
    end
  end

  def submission_params
    params[:submission].permit(:assignment_id, :user_id, :student_notes,
                               :auto_score, :calc_score,:updated_at, :upload,
                               :grading_output, :grading_uid, :team_id,
                               :teacher_score, :teacher_notes,
                               :ignore_late_penalty, :upload_file)
  end
end
