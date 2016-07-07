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

    @file_contents = []
    @file_types = []
    if @submission.file_name =~ /.*\.(tar|tgz|tar.gz)/
      stats = `tar tvf #{@submission.file_full_path}`.split("\n")
      stats.each do |s|
        @file_contents.push s
      end
    else
      f = File.open(@submission.file_full_path.to_s)
      @file_contents.push(f.read)
      @file_types.push (case File.extname(@submission.file_full_path.to_s)
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
      end)
      f.close
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
    if @assignment.team_subs?
      @team = current_user.active_team(@course)
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
