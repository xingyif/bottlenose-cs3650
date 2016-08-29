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
      respond_to do |f|
        f.json { autosave_comments }
        f.html { save_all_comments }
      end
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


  protected 
  def comments_params
    if params[:comments].is_a? String
      JSON.parse(params[:comments])
    else
      params[:comments]
    end
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

  def autosave_comments
    cp = comments_params
    comments = cp.map do |c| comment_to_inlinecomment c end
    data = cp.zip(comments).map do |c, comm| [c["id"], comm.id] end.to_h
    render :json => data
  end

  def save_all_comments
    cp = comments_params
    # delete the ones marked for deletion
    to_delete = InlineComment.where(user: current_user, submission_id: params[:submission_id])
                .where(id: cp.select{|c| c["shouldDelete"]}.map{|c| c["id"].to_i})
    to_delete.destroy_all
    # create the others
    comments = cp.map do |c| comment_to_inlinecomment c end
    data = cp.zip(comments).map do |c, comm| [c["id"], comm.id] end.to_h
    @grader.grader_config.grade(@assignment, @submission)
    @submission.compute_grade! if @submission.grade_complete?
    redirect_to back_or_else(course_assignment_submission_path(@course, @assignment, @submission)),
                message: "Comments saved; grading completed"
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

  def CheckerGrader(edit)
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

  def ManualGrader(edit)
    if edit
      @lineCommentsByFile = @submission.grader_line_comments(current_user)
      # @lineCommentsByFile.each do |file, cBF|
      #   cBF.each do |type, byType|
      #     byType.each do |line, byLine|
      #       byLine.each do |comment|
      #         if comment[:info] and comment[:info]["filename"]
      #           comment[:info]["filename"] = Upload.upload_path_for(comment[:info]["filename"])
      #         end
      #       end
      #     end
      #   end
      # end
      
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
      @submission_dirs = @submission.upload.extracted_files.map{|i| with_extracted(i)}
      render "edit_#{@grader.grader_config.type}"
    else
      redirect_to details_course_assignment_submission_path(@course, @assignment, @submission)
    end
  end

end
