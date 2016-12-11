require 'tap_parser'

class GradersController < ApplicationController
  prepend_before_action :find_grader
  prepend_before_action :find_submission, except: [:bulk_edit, :bulk_update]
  prepend_before_action :find_course_assignment
  before_action :require_admin_or_staff, except: [:show, :update, :details]
  def edit
    if @grader.grader_config.autograde?
      redirect_to back_or_else(course_assignment_submission_path(@course, @assignment, @submission)),
                  alert: "That grader is automatic; there is nothing to edit"
      return
    end

    self.send("edit_#{@grader.grader_config.type}")
  end

  def show
    if !(current_user_site_admin? || current_user_staff_for?(@course)) and !@grader.available
      redirect_to back_or_else(course_assignment_submission_path(@course, @assignment, @submission)),
                  alert: "That grader is not yet available"
      return
    end
    self.send("show_#{@grader.grader_config.type}")
  end

  def regrade
    @grader.grader_config.grade(@assignment, @submission)
    @submission.compute_grade! if @submission.grade_complete?
    redirect_to back_or_else(course_assignment_submission_path(@course, @assignment, @submission))
  end

  def bulk_edit
    self.send("bulk_edit_#{@assignment.type.capitalize}")
  end
  
  def bulk_update
    self.send("bulk_update_#{@assignment.type.capitalize}")
  end

  def update
    if current_user_site_admin? || current_user_staff_for?(@course)
      self.send("update_#{@assignment.type.capitalize}")
    else
      respond_to do |f|
        f.json { render :json => {unauthorized: "Must be an admin or staff"} }
        f.html { 
          redirect_to back_or_else(course_assignment_submission_path(@course, @assignment, @submission)),
                      alert: "Must be an admin or staff."
        }
      end
    end
  end

  def details
    if !(current_user_site_admin? || current_user_staff_for?(@course)) and !@grader.available
      redirect_to back_or_else(course_assignment_submission_path(@course, @assignment, @submission)),
                  alert: "That grader is not yet available"
      return
    end
    respond_to do |f|
      f.text {
        render :text => self.send("details_#{@grader.grader_config.type}")
      }
    end
  end
  
  def self.pretty_print_comments(comments)
    by_file = comments.group_by(&:upload_filename)
    ans = by_file.map do |fn, cs|
      fn.gsub(Regexp.new(".*extracted/?"), "") + ":\n" + cs.sort_by(&:line).map do |c|
        c.to_s(true, false)
      end.join("\n")        
    end
    ans.join("\n==================================================\n")
  end
  
  protected 
  def comments_params
    if params[:comments].is_a? String
      JSON.parse(params[:comments])
    else
      params[:comments]
    end
  end
  def questions_params
    array_from_hash(params[:grades])
  end

  def require_admin_or_staff
    unless current_user_site_admin? || current_user_staff_for?(@course)
      msg = "Must be an admin or staff."
      if @course
        if @assignment
          if @submission
            redirect_to back_or_else(course_assignment_submission_path(@course, @assignment, @submission)), alert: msg
          else
            redirect_to back_or_else(course_assignment_path(@course, @assignment)), alert: msg
          end
        else
          redirect_to back_or_else(course_path(@course)), alert: msg
        end
      else
          redirect_to back_or_else(root_path), alert: msg
      end        
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
    @submission = Submission.find_by(id: params[:submission_id])
    if @submission.nil? or @submission.assignment_id != @assignment.id
      redirect_to back_or_else(course_assignment_path(@course, @assignment)),
                  alert: "No such submission for this assignment"
      return
    end
  end
  
  def find_grader
    @grader = Grader.find_by(id: params[:id])
    if @grader.nil?
      redirect_to back_or_else(course_assignment_submission_path(params[:course_id],
                                                                 params[:assignment_id],
                                                                 params[:submission_id])),
                  alert: "No such grader"
      return
    elsif @submission and @grader.submission_id != @submission.id
      redirect_to back_or_else(course_assignment_submission_path(params[:course_id],
                                                                 params[:assignment_id],
                                                                 params[:submission_id])),
                  alert: "No such grader for that submission"
    end
  end

  def do_save_comments(cp, cp_to_comment)
    # delete the ones marked for deletion
    deletable, commentable = cp.partition{|c| c["shouldDelete"]}
    to_delete = InlineComment.where(submission_id: params[:submission_id])
                .where(id: deletable.map{|c| c["id"].to_i}.select{|i| i < (1 << 31)})
    unless current_user_prof_for?(@course)
      to_delete = to_delete.where(user: current_user)  # Only professors can delete other grader's comments
    end
    to_delete.destroy_all
    deleted = deletable.map do |c| [c["id"], "deleted"] end.to_h
    # create the others
    comments = InlineComment.transaction do
      commentable.map do |c| self.send(cp_to_comment, c) end
    end
    newdata = commentable.zip(comments).map do |c, comm| [c["id"], comm.id] end.to_h
    newdata.merge(deleted)
  end
  
  def autosave_comments(cp, cp_to_comment)
    render :json => do_save_comments(cp, cp_to_comment)
  end

  def save_all_comments(cp, cp_to_comment)
    do_save_comments(cp, cp_to_comment)
    @grader.grader_config.grade(@assignment, @submission)
    @submission.compute_grade! if @submission.grade_complete?
  end

  def comment_to_inlinecomment(c)
    if c["id"]
      comment = InlineComment.find_by(id: c["id"].to_i)
    end
    if comment.nil?
      comment = InlineComment.new
    end
    if c["shouldDelete"]
      comment
    else
      comment.update(submission_id: params[:submission_id],
                     label: c["label"],
                     filename: Upload.full_path_for(c["file"]),
                     line: c["line"],
                     grader_id: @grader.id,
                     user_id: current_user.id,
                     severity: c["severity"],
                     comment: c["comment"],
                     weight: c["deduction"],
                     suppressed: false,
                     title: "",
                     info: nil)
      comment
    end
  end

  def question_to_inlinecomment(c)
    comment = InlineComment.find_or_initialize_by(submission_id: params[:submission_id],
                                                  grader_id: @grader.id,
                                                  line: c["index"])
    comment.update(label: "Graded question",
                   filename: @submission.upload.submission_path,
                   severity: InlineComment.severities["info"],
                   user_id: current_user.id,
                   weight: c["score"],
                   comment: c["comment"],
                   suppressed: false,
                   title: "",
                   info: nil)
    comment
  end

  ###################################
  # Per-assignment-type actions, by action
  # Bulk editing of grades
  def bulk_edit_Exam
    edit_exam_grades_for(@course.students)
    
    render "edit_#{@assignment.type.underscore}_grades"
  end
  def bulk_edit_Files
    redirect_to back_or_else(course_assignment_path(@course, @assignment)),
                alert: "Bulk grade editing for that assignment type is not supported"
  end
  def bulk_edit_Questions
    redirect_to back_or_else(course_assignment_path(@course, @assignment)),
                alert: "Bulk grade editing for that assignment type is not supported"
  end

  # Bulk updates of grades
  def bulk_update_Exam
    update_exam_grades
    redirect_to back_or_else(course_assignment_path(@course, @assignment)),
                    notice: "Grades saved"
  end
  def bulk_update_Files
    redirect_to back_or_else(course_assignment_path(@course, @assignment)),
                alert: "Bulk grade updating for that assignment type is not supported"
  end
  def bulk_update_Questions
    redirect_to back_or_else(course_assignment_path(@course, @assignment)),
                alert: "Bulk grade updating for that assignment type is not supported"
  end

  # Individual updates, mostly of comments
  def update_Files
    respond_to do |f|
      f.json { autosave_comments(comments_params, :comment_to_inlinecomment) }
      f.html {
        save_all_comments(comments_params, :comment_to_inlinecomment)
        redirect_to course_assignment_submission_path(@course, @assignment, @submission),
                    notice: "Comments saved; grading completed"
      }
    end
  end
  def update_Questions
    missing, qp = questions_params.partition{|q| q["score"].nil? or q["score"].empty? }
    missing = missing.map{|q| q["index"].to_i + 1}

    save_all_comments(qp, :question_to_inlinecomment)
    if missing.empty?
      redirect_to course_assignment_submission_path(@course, @assignment, @submission),
                  notice: "Comments saved; grading completed"
    else
      if missing.count > 1
        msg = "Questions #{missing.join(', ')} do not have grades"
      else
        msg = "Question #{missing[0]} does not have a grade"
      end
      redirect_to :back, alert: msg
    end
  end
  def update_Exam
    update_exam_grades
    redirect_to course_assignment_submission_path(@course, @assignment, @submission),
                notice: "Grades saved"
  end

  ###################################
  # Grader responses, by grader type

  # JavaStyleGrader
  def show_JavaStyleGrader
    get_submission_files(@submission, nil, "JavaStyleGrader")
    @commentType = "JavaStyleGrader"
    if @grader.grading_output
      begin
        @grading_output = File.read(@grader.grading_output)
        begin
          tap = TapParser.new(@grading_output)
          @grading_output = tap
          @tests = tap.tests
        rescue Exception
          @tests = []
        end
      rescue Errno::ENOENT
        @grading_output = "Grading output file is missing or could not be read"
        @tests = []
      end
    end
    num_comments = @grader.inline_comments.count
    if @tests.nil? or @tests.count != num_comments
      @error_header = <<HEADER.html_safe
<p>There seems to be a problem displaying the style-checker's feedback on this submission.</p>
<p>Please email the professor, with the following information:</p>
<ul>
<li>Course: #{@course.id}</li>
<li>Assignment: #{@assignment.id}</li>
<li>Submission: #{@submission.id}</li>
<li>Grader: #{@grader.id}</li>
<li>User: #{current_user.name} (#{current_user.id})</li>
</li>
HEADER
    end
    render "show_JavaStyleGrader"
    # debugger
    # redirect_to details_course_assignment_submission_path(@course, @assignment, @submission)
  end
  def edit_JavaStyleGrader
    redirect_to details_course_assignment_submission_path(@course, @assignment, @submission)
  end
  def details_JavaStyleGrader
    GradersController.pretty_print_comments(@grader.inline_comments)
  end

  # JunitGrader
  def show_JunitGrader
    if @grader.grading_output
      begin
        @grading_output = File.read(@grader.grading_output)
        begin
          tap = TapParser.new(@grading_output)
          @grading_output = tap
          @tests = tap.tests
        rescue Exception
          @tests = []
        end
      rescue Errno::ENOENT
        @grading_output = "Grading output file is missing or could not be read"
        @tests = []
      end
    end

    if current_user_site_admin? || current_user_staff_for?(@course)
      if @grading_output.kind_of?(String)
        @grading_header = "Errors running tests"
      else
        @grading_header = "All test results"
        @tests = @grading_output.tests
      end
    else
      if @grading_output.kind_of?(String)
        @grading_header = "Errors running tests"
      elsif @grading_output.passed_count == @grading_output.test_count
        @grading_header = "Test results"
        @tests = @grading_output.tests
      else
        @grading_header = "Selected test results"
        @tests = @grading_output.tests.delete_if{|t| t[:passed]}.shuffle.take(3)
      end
    end

    render "show_JunitGrader"
  end
  def details_JunitGrader
    "No details to show for Junit grader"
  end

  # CheckerGrader
  def show_CheckerGrader
    if @grader.grading_output
      begin
        @grading_output = File.read(@grader.grading_output)
        begin
          tap = TapParser.new(@grading_output)
          @grading_output = tap
          @tests = tap.tests
        rescue Exception
          @tests = []
        end
      rescue Errno::ENOENT
        @grading_output = "Grading output file is missing or could not be read"
        @tests = []
      end
    end

    if current_user_site_admin? || current_user_staff_for?(@course)
      if @grading_output.kind_of?(String)
        @grading_header = "Errors running tests"
      else
        @grading_header = "All test results"
        @tests = @grading_output.tests
      end
    else
      if @grading_output.kind_of?(String)
        @grading_header = "Errors running tests"
      elsif @grading_output.passed_count == @grading_output.test_count
        @grading_header = "All tests passed"
      else
        @grading_header = "Selected test results"
        @tests = @grading_output.tests.delete_if{|t| t[:passed]}.shuffle.take(3)
      end
    end

    render "show_CheckerGrader"
  end
  def details_CheckerGrader
    GradersController.pretty_print_comments(@grader.inline_comments)
  end

  # QuestionsGrader
  def edit_QuestionsGrader
    @questions = @assignment.questions
    @answers = YAML.load(File.open(@submission.upload.submission_path))

    @submission_dirs = []
    if @assignment.related_assignment
      related_sub = @assignment.related_assignment.used_sub_for(@submission.user)
      if related_sub.nil?
        @submission_files = []
        @answers_are_newer = true
      else
        get_submission_files(related_sub)
        @answers_are_newer = (related_sub.created_at < @submission.created_at)        
      end
    else
      @submission_files = []
      @answers_are_newer = true
    end
    show_hidden = (current_user_site_admin? || current_user_staff_for?(@course))
    pregrades = @submission.inline_comments(current_user)
    pregrades = pregrades.select(:line, :name, :weight, :comment).joins(:user).sort_by(&:line).to_a
    @grades = []
    pregrades.each do |g| @grades[g["line"]] = g end
    @show_graders = true
    render "edit_QuestionsGrader"
  end
  def show_QuestionsGrader
    @questions = @assignment.questions
    @answers = YAML.load(File.open(@submission.upload.submission_path))
    redirect_to details_course_assignment_submission_path(@course, @assignment, @submission)
  end
  def details_QuestionsGrader
    "No details to show for Questions grader"
  end

  # ManualGrader
  def edit_ManualGrader
    show_hidden = (current_user_site_admin? || current_user_staff_for?(@course))
    @lineCommentsByFile = @submission.grader_line_comments(current_user, show_hidden)
    get_submission_files(@submission, @lineCommentsByFile)
    render "edit_ManualGrader"
  end
  def show_ManualGrader
    get_submission_files(@submission, nil, "ManualGrader")
    @commentType = "ManualGrader"
    render "submissions/details_files"
#    redirect_to details_course_assignment_submission_path(@course, @assignment, @submission)
  end
  def details_ManualGrader
    GradersController.pretty_print_comments(@grader.inline_comments)
  end

  # ExamGrader
  def edit_ExamGrader
    edit_exam_grades_for(User.where(id: @submission.user_id))
    render "edit_ExamGrader"
  end
  def show_ExamGrader
    redirect_to course_assignment_submission_path(@course, @assignment, @submission)
  end
  def details_QuestionsGrader
    "No details to show for Exam grader"
  end

  def edit_SandboxGrader
    redirect_to details_course_assignment_submission_path(@course, @assignment, @submission)
  end
  def show_SandboxGrader
    render "show_SandboxGrader"
  end
  def details_SanboxGrader
    @grader.notes
  end

  

  ##############################
  def edit_exam_grades_for(students)
    @student_info = students.select(:username, :last_name, :first_name, :id)
    @used_subs = @assignment.used_submissions
    @grade_comments = InlineComment.where(submission_id: @used_subs.map(&:id)).group_by(&:submission_id)
  end

  def update_exam_grades
    all_grades = array_from_hash(params[:student])
    @student_info = @course.students.select(:username, :last_name, :first_name, :id).where(id: params[:student].keys)
    @grader_config = @assignment.grader_configs.first # and only config
    # @used_subs = @assignment.used_submissions
    # @grade_comments = InlineComment.where(submission_id: @used_subs.map(&:id)).group_by(&:user_id)
    
    @student_info.each do |student|
      @sub = @assignment.used_sub_for(student)
      if @sub.nil?
        @sub = Submission.create!(assignment: @assignment,
                                  user: student,
                                  type: "Exam",
                                  created_at: @assignment.due_date - 1.minute)
      end
      @sub.set_used_sub!
      @grader = Grader.find_or_create_by(grader_config_id: @grader_config.id, submission_id: @sub.id)
      if @grader.new_record?
        @grader.out_of = @grader_config.avail_score
      end
      grades = all_grades[student.id]
      flattened = @assignment.flattened_questions
      grades.each_with_index do |g, q_num|
        comment = InlineComment.find_or_initialize_by(submission_id: @sub.id, grader_id: @grader.id, line: q_num)
        if g.to_s.empty?
          if comment.new_record?
            next # no need to save blanks
          else
            comment.delete
          end
        else
          comment.update(label: "Exam question",
                         filename: @assignment.name,
                         severity: InlineComment.severities["info"],
                         user_id: current_user.id,
                         weight: g,
                         comment: "",
                         suppressed: false,
                         title: "",
                         info: nil)
        end
      end
      @grader_config.expect_num_questions(flattened.count)
      @grader_config.grade(@assignment, @sub)
    end
  end

end
