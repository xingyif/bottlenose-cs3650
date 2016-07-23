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

    @commentsByFile = @submission.grader_comments
    @commentsByFile.each do |file, cBF|
      cBF.each do |line, byLine|
        byLine.each do |comment|
          if comment[:info] and comment[:info]["filename"]
            comment[:info]["filename"] = Upload.upload_path_for(comment[:info]["filename"])
          end
        end
      end
    end
    
    @submission_files = []
    def with_extracted(item)
      if item[:public_link]
        @submission_files.push({
          link: item[:public_link],
          name: item[:public_link].sub(/^.*extracted\//, ""),
          contents: File.read(item[:full_path].to_s),
          type: case File.extname(item[:full_path].to_s)
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
                end,
          comments: @commentsByFile[item[:full_path].to_s] || {}
          })
        { text: item[:path], href: "#file_#{@submission_files.count}" }
      else
        {
          text: item[:path] + "/",
          state: {selectable: false},
          nodes: item[:children].map{|i| with_extracted(i)}
        }
      end
    end
    @submission_dirs = JSON.pretty_generate(@submission.upload.extracted_files.map{|i| with_extracted(i)})
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
      @submission.autograde!
      path = course_assignment_submission_path(@course, @assignment, @submission)
      redirect_to(path, notice: 'Submission was successfully created.')
    else
      @submission.cleanup!
      render :new
    end
  end

  def use_for_grading
    unless current_user.site_admin? || current_user.registration_for(@course).staff?
      redirect_to root_path, alert: "Must be an admin or staff."
      return
    end
    @submission = Submission.find(params[:id])
    @submission.set_used_sub!
    redirect_to :back
  end

  def publish
    unless current_user.site_admin? || current_user.registration_for(@course).staff?
      redirect_to root_path, alert: "Must be an admin or staff."
      return
    end
    @submission = Submission.find(params[:id])
    @submission.graders.update_all(:available => true)
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
