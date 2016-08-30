require 'tap_parser'

class GradersController < ApplicationController
  prepend_before_action :find_grader
  prepend_before_action :find_course_assignment_submission
  before_action :require_admin_or_staff, except: [:show, :update]
  def edit
    if @grader.grader_config.autograde?
      redirect_to back_or_else(course_assignment_submission_path(@course, @assignment, @submission)),
                  alert: "That grader is automatic; there is nothing to edit"
      return
    end

    self.send(@grader.grader_config.type, true) if self.respond_to?(@grader.grader_config.type, true)
  end

  def show
    if @grader.grading_output
      @grading_output = File.read(@grader.grading_output)
      begin
        tap = TapParser.new(@grading_output)
        @grading_output = tap
      rescue Exception
      end
    end

    self.send(@grader.grader_config.type, false) if self.respond_to?(@grader.grader_config.type, true)
  end

  def regrade
    @grader.grader_config.grade(@assignment, @submission)
    @submission.compute_grade! if @submission.grade_complete?
    redirect_to back_or_else(course_assignment_submission_path(@course, @assignment, @submission))
  end
  
  def update
    if current_user_site_admin? || current_user_staff_for?(@course)
      self.send("update_#{@assignment.type.capitalize}", false) if self.respond_to?("update_#{@assignment.type.capitalize}", true)
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
  def update_Files(edit)
    respond_to do |f|
      f.json { autosave_comments(comments_params, :comment_to_inlinecomment) }
      f.html {
        save_all_comments(comments_params, :comment_to_inlinecomment)
        redirect_to course_assignment_submission_path(@course, @assignment, @submission),
                    notice: "Comments saved; grading completed"
      }
    end
  end
  def update_Questions(edit)
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
      redirect_to back_or_else(course_assignment_submission_path(@course, @assignment, @submission)),
                  alert: "Must be an admin or staff."
      return
    end
  end

  def find_course_assignment_submission
    @course = Course.find_by(id: params[:course_id])
    @assignment = Assignment.find_by(id: params[:assignment_id])
    @submission = Submission.find_by(id: params[:submission_id])
    if @course.nil?
      redirect_to back_or_else(root_path), alert: "No such course"
      return
    end
    if @assignment.nil? or @assignment.course_id != @course.id
      redirect_to back_or_else(course_path(@course)), alert: "No such assignment for this course"
      return
    end
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
    end
  end

  def autosave_comments(cp, cp_to_comment)
    comments = cp.map do |c| self.send(cp_to_comment, c) end
    data = cp.zip(comments).map do |c, comm| [c["id"], comm.id] end.to_h
    render :json => data
  end

  def save_all_comments(cp, cp_to_comment)
    # delete the ones marked for deletion
    to_delete = InlineComment.where(user: current_user, submission_id: params[:submission_id])
                .where(id: cp.select{|c| c["shouldDelete"]}.map{|c| c["id"].to_i})
    to_delete.destroy_all
    # create the others
    comments = cp.map do |c| self.send(cp_to_comment, c) end
    data = cp.zip(comments).map do |c, comm| [c["id"], comm.id] end.to_h
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
  # Grader responses
  
  def JavaStyleGrader(edit)
    redirect_to details_course_assignment_submission_path(@course, @assignment, @submission),
                flash: {show_comments: true}
  end

  def JunitGrader(edit)
    if @grader.grading_output
      @grading_output = File.read(@grader.grading_output)
      begin
        tap = TapParser.new(@grading_output)
        @grading_output = tap
        @tests = tap.tests
      rescue Exception
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
        @tests = @grading_output.tets
      else
        @grading_header = "Selected test results"
        @tests = @grading_output.tests.delete_if{|t| t[:passed]}.shuffle.take(3)
      end
    end

    render "show_JunitGrader"
  end

  def grade_CheckerGrader(edit)
    if @grader.grading_output
      @grading_output = File.read(@grader.grading_output)
      begin
        tap = TapParser.new(@grading_output)
        @grading_output = tap
        @tests = tap.tests
      rescue Exception
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

  def QuestionsGrader(edit)
    @questions = @assignment.questions
    @answers = YAML.load(File.open(@submission.upload.submission_path))
    if edit
      @submission_dirs = []
      if @assignment.related_assignment
        related_sub = @assignment.related_assignment.used_sub_for(@submission.user)
        if related_sub.nil?
          @submission_files = []
        else
          get_submission_files(related_sub)
        end
      else
        @submission_files = []
      end
      show_hidden = (current_user_site_admin? || current_user_staff_for?(@course))
      @grades = @submission.inline_comments(current_user)
      @grades = @grades.select(:line, :name, :weight, :comment).joins(:user).sort_by(&:line).to_a
      @show_graders = true
      render "edit_QuestionsGrader"
    else
      redirect_to details_course_assignment_submission_path(@course, @assignment, @submission)
    end
  end
  
  def ManualGrader(edit)
    if edit
      show_hidden = (current_user_site_admin? || current_user_staff_for?(@course))
      @lineCommentsByFile = @submission.grader_line_comments(current_user, show_hidden)
      get_submission_files(@submission)
      render "edit_ManualGrader"
    else
      redirect_to details_course_assignment_submission_path(@course, @assignment, @submission)
    end
  end

  def get_submission_files(sub)
    @submission_files = []
    @lineCommentsByFile = {}
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
  
end
