class SubmissionsController < ApplicationController
  before_filter :require_student

  def show
    @submission = Submission.find(params[:id])
    @assignment = @submission.assignment

    unless @submission.visible_to?(current_user)
      show_error "That's not your submission."
      redirect_to @assignment
    end
  end

  def new
    @assignment = Assignment.find(params[:assignment_id])
    @submission = Submission.new
    @submission.assignment_id = @assignment.id
    @submission.user_id = current_user.id

    if @assignment.team_subs?
      @team = current_user.active_team(@course)
      @submission.team = @team
    end
  end

  def create
    @assignment = Assignment.find(params[:assignment_id])
    @submission = Submission.new(submission_params)
    @submission.assignment_id = @assignment.id

    @row_user = User.find_by_id(params[:row_user_id])

    if current_user.course_admin?(@course)
      @submission.user ||= current_user
    else
      @submission.user = current_user
      @submission.ignore_late_penalty = false
    end

    @submission.save_upload!

    if @submission.save
      @team = @submission.team

      @submission.grade!
      path = course_assignment_submission_path(@course, @assignment, @submission)
      redirect_to(path, notice: 'Submission was successfully created.')
    else
      @submission.cleanup!
      render :new
    end
  end

  private

  def submission_params
    if current_user.course_admin?(@course)
      params[:submission].permit(:assignment_id, :user_id, :student_notes,
                                 :auto_score, :calc_score, :updated_at, :upload,
                                 :grading_output, :grading_uid, :team_id,
                                 :teacher_score, :teacher_notes,
                                 :ignore_late_penalty, :upload_file,
                                 :comments_upload_file)
    else
      params[:submission].permit(:assignment_id, :user_id, :student_notes,
                                 :upload, :upload_file)
    end
  end
end
