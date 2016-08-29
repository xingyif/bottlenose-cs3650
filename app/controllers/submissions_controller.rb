require 'tempfile'

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

    self.send("show_#{@assignment.type.capitalize}", false) if self.respond_to?("show_#{@assignment.type.capitalize}", true)
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

    self.send("new_#{@assignment.type.capitalize}", false) if self.respond_to?("new_#{@assignment.type.capitalize}", true)
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


    self.send("create_#{@assignment.type.capitalize}", false) if self.respond_to?("create_#{@assignment.type.capitalize}", true)
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

  def answers_params
    array_from_hash(params[:answers])
  end
  def array_from_hash(h)
    return h unless h.is_a? Hash

    all_numbers = h.keys.all? { |k| k.to_i.to_s == k }
    if all_numbers
      ans = []
      h.keys.sort_by{ |k| k.to_i }.map{ |i| ans[i.to_i] = array_from_hash(h[i]) }
      ans
    else
      ans = {}
      h.each do |k, v|
        ans[k] = array_from_hash(v)
      end
      ans
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
    
    @submission_dirs = sub.upload.extracted_files.map{|i| with_extracted(i)}
  end


  ######################
  # Assignment types
  def new_Questions(edit)
    @questions = @assignment.questions
    if @assignment.related_assignment
      related_sub = @assignment.related_assignment.used_sub_for(current_user)
      if related_sub.nil?
        @submission_files = []
      else
        get_submission_files(related_sub)
      end
    else
      @submission_files = []
    end
  end

  def show_Files(edit)
    @gradesheet = Gradesheet.new(@assignment, [@submission])
  end
  
  def show_Questions(edit)
    @questions = @assignment.questions
    @answers = YAML.load(File.open(@submission.upload.submission_path))
  end
  
  def create_Files(edit)
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

  def create_Questions(edit)
    @answers = answers_params
    questions = @assignment.questions.reduce([]) do |acc, section|
      section.reduce(acc) do |acc, (name, qs)| acc + qs end
    end
    num_qs = questions.count
    no_problems = true
    if @answers.count != num_qs
      @submission.errors.add(:base, "There were #{plural(@answers.count, 'answer')} for #{plural(num_qs, 'question')}")
      @submission.cleanup!
      no_problems = false
    else
      questions.zip(@answers).each_with_index do |(q, a), i|
        if a["main"].nil?
          @submission.errors.add(:base, "Question #{i + 1} is missing an answer")
          no_problems = false
        end
        if q["YesNo"]
          type = "YesNo"
          unless ["yes", "no"].member?(a["main"].downcase)
            @submission.errors.add(:base, "Question #{i + 1} has a non-Yes/No answer")
            no_problems = false
          end
        elsif q["TrueFalse"]
          type = "TrueFalse"
          unless ["true", "false"].member?(a["main"].downcase)
            @submission.errors.add(:base, "Question #{i + 1} has non-true/false answer")
            no_problems = false
          end
        elsif q["Numeric"]
          type = "Numeric"
          if !(Float(a["main"]) rescue false)
            @submission.errors.add(:base, "Question #{i + 1} has a non-numeric answer")
            no_problems = false
          end
        elsif q["MultipleChoice"]
          type = "MultipleChoice"
          if a["main"].nil?
            # nothing, was handled above
          elsif !(Integer(a["main"]) rescue false)
            @submission.errors.add(:base, "Question #{i + 1} has an invalid multiple-choice answer")
            no_problems = false
          elsif a["main"].to_i < 0 or a["main"].to_i >= q[type]["options"].count
            @submission.errors.add(:base, "Question #{i + 1} has an invalid multiple-choice answer")
            no_problems = false
          end
        elsif q["Text"]
          type = "Text"
        end
        if q[type]["parts"]
          if a["parts"].nil? or q[type]["parts"].count != a["parts"].count
            @submission.errors.add(:base, "Question #{i + 1} is missing answers to its sub-parts")
            no_problems = false
          else
            q[type]["parts"].zip(a["parts"]).each_with_index do |(qp, ap), j|
              if qp["codeTag"]
                if ap["file"].to_s.empty? or !(Integer(ap["line"]) rescue false)
                  @submission.errors.add(:base, "Question #{i + 1} part #{j + 1} has an invalid code-tag")
                  no_problems = false
                end
              elsif qp["codeTags"]
                # TODO
              elsif qp["text"]
                # TODO
              elsif qp["requiredText"]
                if ap["info"].to_s.empty?
                  @submission.errors.add(:base, "Question #{i + 1} part #{j + 1} has a missing required text answer")
                  no_problems = false
                end
              end
            end
          end
        end
      end
    end

    if no_problems
      Tempfile.open('answers.yaml', Rails.root.join('tmp')) do |f|
        f.write(YAML.dump(@answers))
        f.flush
        f.rewind
        uploadfile = ActionDispatch::Http::UploadedFile.new(filename: "answers.yaml", tempfile: f)
        @submission.upload_file = uploadfile
        @submission.save_upload
      end
      @submission.save
      @submission.set_used_sub!
      path = course_assignment_submission_path(@course, @assignment, @submission)
      redirect_to(path, notice: 'Response was successfully created.')
    else
      new_Questions(false)
      render "new_#{@assignment.type.underscore}"
    end      
  end
end
