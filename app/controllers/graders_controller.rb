require 'tap_parser'

class GradersController < ApplicationController
  def edit
    @grader = Grader.find(params[:id])
    @course = Course.find(params[:course_id])
    @assignment = Assignment.find(params[:assignment_id])
    @submission = Submission.find(params[:submission_id])

    unless current_user_site_admin? || current_user_staff_for?(@course)
      redirect_to :back, alert: "Must be an admin or staff."
      return
    end
    
    if @grader.grader_config.autograde?
      redirect_to :back, alert: "That grader is automatic; there is nothing to edit"
      return
    end

    self.send(@grader.grader_config.type, true) if self.respond_to?(@grader.grader_config.type)
  end

  def show
    @grader = Grader.find(params[:id])
    @course = Course.find(params[:course_id])
    @assignment = Assignment.find(params[:assignment_id])
    @submission = Submission.find(params[:submission_id])

    if @grader.grading_output
      @grading_output = File.read(@grader.grading_output)
      begin
        tap = TapParser.new(@grading_output)
        @grading_output = tap
      rescue Exception
      end
    end

    self.send(@grader.grader_config.type, false) if self.respond_to?(@grader.grader_config.type)
  end

  def regrade
    unless current_user_site_admin? || current_user_staff_for?(@course)
      redirect_to :back, alert: "Must be an admin or staff."
      return
    end
    @grader = Grader.find(params[:id])
    @assignment = Assignment.find(params[:assignment_id])
    @submission = Submission.find(params[:submission_id])
    @grader.grader_config.grade(@assignment, @submission)
    @submission.compute_grade! if @submission.grade_complete?
    redirect_to :back
  end
  
  def update
    @grader = Grader.find(params[:id])
    @assignment = Assignment.find(params[:assignment_id])
    @submission = Submission.find(params[:submission_id])
    respond_to do |f|
      f.json { autosave_comments }
      f.html { save_all_comments }
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
    redirect_to :back, message: "Comments saved; grading completed"
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
  
  def JavaStyleGrader(edit)
    redirect_to files_course_assignment_submission_path(@course, @assignment, @submission)
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
      @submission_dirs = JSON.pretty_generate(@submission.upload.extracted_files.map{|i| with_extracted(i)})
      render "edit_#{@grader.grader_config.type}"
    else
      redirect_to files_course_assignment_submission_path(@course, @assignment, @submission)
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
end
