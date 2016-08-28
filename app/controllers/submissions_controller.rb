class SubmissionsController < CoursesController
  prepend_before_action :find_submission, except: [:index, :new, :create]
  prepend_before_action :find_course_assignment
  before_action :require_current_user, only: [:show, :files, :new, :create]
  before_action :require_admin_or_staff, only: [:recreate_grader, :use_for_grading, :publish]
  def show
    unless @submission.visible_to?(current_user)
      redirect_to course_assignment_path(@course, @assignment), alert: "That's not your submission."
      return
    end

    @gradesheet = Gradesheet.new(@assignment, [@submission])
    render "show_#{@assignment.type.underscore}"
  end

  def index
    redirect_to course_assignment_path(@course, @assignment)
  end

  def files
    unless @submission.visible_to?(current_user)
      redirect_to course_assignment_path(@course, @assignment), alert: "That's not your submission."
      return
    end

    get_submission_files(@submission)
  end

  def new
    @submission = Submission.new
    @submission.assignment_id = @assignment.id
    @submission.user_id = current_user.id

    if @assignment.team_subs?
      @team = current_user.active_team_for(@course)
      @submission.team = @team
    end

    self.send(@assignment.type.capitalize, false) if self.respond_to?(@assignment.type.capitalize, true)
    render "new_#{@assignment.type.underscore}"
  end

  def create
    @submission = Submission.new(submission_params)
    @submission.assignment_id = @assignment.id
    if @assignment.team_subs?
      @team = current_user.active_team_for(@course)
      @submission.team = @team
    end

    @row_user = User.find_by_id(params[:row_user_id])

    if true_user_staff_for?(@course) || current_user_staff_for?(@course)
      @submission.user ||= current_user
      @submission.ignore_late_penalty = (submission_params[:ignore_late_penalty].to_i > 0)
      if submission_params[:created_at] and !@submission.ignore_late_penalty
        @submission.created_at = DateTime.parse(submission_params[:created_at])
      end
    else
      @submission.user = current_user
      @submission.ignore_late_penalty = false
    end

    # TODO: per-assignment-type processing, to save question answers as upload
    
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

  def recreate_grader
    if @submission.recreate_missing_grader(@grader_config)
      @submission.compute_grade! if @submission.grade_complete?
      redirect_to back_or_else(course_assignment_submission_path(@course, @assignment, @submission))
    else
      redirect_to back_or_else(course_assignment_submission_path(@course, @assignment, @submission)),
                  alert: "Grader already exists; use Regrade to modify it instead"
    end
  end

  def use_for_grading
    @submission.set_used_sub!
    redirect_to back_or_else(course_assignment_submission_path(@course, @assignment, @submission))
  end

  def publish
    @submission.graders.where(score: nil).each do |g| g.grade(assignment, used) end
    @submission.graders.update_all(:available => true)
    @submission.compute_grade!
    redirect_to back_or_else(course_assignment_submission_path(@course, @assignment, @submission))
  end
  
  private

  def submission_params
    if true_user_prof_for?(@course) or current_user_prof_for?(@course)
      params[:submission].permit(:assignment_id, :user_id, :student_notes,
                                 :auto_score, :calc_score, :created_at, :updated_at, :upload,
                                 :grading_output, :grading_uid, :team_id,
                                 :teacher_score, :teacher_notes,
                                 :ignore_late_penalty, :upload_file,
                                 :comments_upload_file)
    else
      params[:submission].permit(:assignment_id, :user_id, :student_notes,
                                 :upload, :upload_file)
    end
  end

  def require_admin_or_staff
    unless current_user_site_admin? || current_user_staff_for?(@course)
      redirect_to back_or_else(course_assignment_submission_path(@course, @assignment, @submission)),
                  alert: "Must be an admin or staff."
      return
    end
  end

  def find_course_assignment
    @course = Course.find_by(id: params[:course_id])
    @assignment = Assignment.find_by(id: params[:assignment_id])
    if @course.nil?
      redirect_to back_or_else(root_path), alert: "No such course"
      return
    end
    if @assignment.nil? or @assignment.course_id != @course.id
      redirect_to back_or_else(course_path(@course)), alert: "No such assignment for this course"
      return
    end
  end
  
  def find_submission
    @submission = Submission.find_by(id: params[:id])
    if @submission.nil?
      redirect_to back_or_else(course_assignment_path(params[:course_id], params[:assignment_id])),
                  alert: "No such submission"
      return
    end
  end

  
  def get_submission_files(sub)
    @lineCommentsByFile = sub.grader_line_comments(nil)

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
          lineComments: @lineCommentsByFile[item[:public_link].to_s] || {}
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
    
    @submission_dirs = JSON.pretty_generate(sub.upload.extracted_files.map{|i| with_extracted(i)})
  end


  ######################
  # Assignment types
  def Questions(edit)
    @questions = @assignment.questions
    related_sub = @assignment.related_assignment.used_sub_for(current_user)
    if related_sub.nil?
      @submission_files = []
    else
      get_submission_files(related_sub)
    end
  end
end
