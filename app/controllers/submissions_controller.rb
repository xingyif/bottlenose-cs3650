class SubmissionsController < CoursesController
  # before_filter :require_student

  def show
    @submission = Submission.find(params[:id])
    @assignment = @submission.assignment

    unless @submission.visible_to?(current_user)
      show_error "That's not your submission."
      redirect_to course_assignment_path(@course, @assignment)
    end

    @gradesheet = Gradesheet.new(@assignment, [@submission])
  end

  def files
    @submission = Submission.find(params[:id])
    @assignment = @submission.assignment

    unless @submission.visible_to?(current_user)
      show_error "That's not your submission."
      redirect_to course_assignment_path(@course, @assignment)
    end

    @submission_files = []
    @submission.upload.extracted_files.each do |item|
      f = File.open(item[:path].to_s)
      contents = f.read
      f.close

      ftype = case File.extname(item[:path].to_s)
              when ".java"
                "text/x-java"
              when ".arr"
                "pyret"
              when ".rkt", ".ss"
                "scheme"
              when ".jpg", ".jpeg", ".png"
                "image"
              when ".jar"
                "jar"
              when ".zip"
                "zip"
              else
                "text/unknown"
              end
      
      @submission_files.push({
        link: item[:public_link],
        contents: contents,
        type: ftype,
        name: item[:public_link].sub(/^.*extracted\//, "")
      })
    end
  end

  def new
    @assignment = Assignment.find(params[:assignment_id])
    @submission = Submission.new
    @submission.assignment_id = @assignment.id
    @submission.user_id = current_user.id

    if @assignment.team_subs?
      @team = current_user.active_team_for(@course)
      @submission.team = @team
    end
  end

  def create
    @assignment = Assignment.find(params[:assignment_id])
    @submission = Submission.new(submission_params)
    @submission.assignment_id = @assignment.id
    if @assignment.team_subs?
      @team = current_user.active_team_for(@course)
      @submission.team = @team
    end

    @row_user = User.find_by_id(params[:row_user_id])

    if current_user.course_staff?(@course)
      @submission.user ||= current_user
      @submission.ignore_late_penalty = true
    else
      @submission.user = current_user
      @submission.ignore_late_penalty = false
    end

    if @submission.save_upload and @submission.save
      @submission.set_used_sub!
      @submission.grade!
      path = course_assignment_submission_path(@course, @assignment, @submission)
      redirect_to(path, notice: 'Submission was successfully created.')
    else
      @submission.cleanup!
      render :new
    end
  end

  def use_for_grading
    @submission = Submission.find(params[:id])
    @submission.set_used_sub!
    redirect_to :back
  end

  private

  def submission_params
    if current_user.course_professor?(@course)
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
