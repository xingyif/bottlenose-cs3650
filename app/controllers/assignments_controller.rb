class AssignmentsController < ApplicationController
  before_filter :require_teacher, :except => [:show]
  before_filter :require_course_permission
  prepend_before_filter :find_assignment

  def index
    @assignments = @chapter.assignments
    @assignments = Assignment.all
  end

  def show
    @submissions = @assignment.submissions.where(user_id: @logged_in_user.id)
  end

  def new
    @assignment = Assignment.new
    @assignment.chapter_id = @chapter.nil? ? nil : @chapter.id
    @assignment.course_id  = @course.id
    @assignment.due_date = (Time.now + 1.month).to_date
    @assignment.points_available = 100
  end

  def edit
  end

  def create
    @assignment = Assignment.new(assignment_params)
    @assignment.course_id = @course.id
    @assignment.blame_id = @logged_in_user.id

    if @assignment.save
      @assignment.save_uploads!
      redirect_to @assignment, notice: 'Assignment was successfully created.'
    else
      render action: "new"
    end
  end

  def update
    if @assignment.update_attributes(assignment_params)
      @assignment.save_uploads!
      redirect_to @assignment, notice: 'Assignment was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    @assignment.destroy
    show_notice "Assignment has been deleted."
    redirect_to @course
  end

  def tarball
    tb = SubTarball.new(@assignment.id)
    tb.update!
    redirect_to tb.path
  end

  private

  def find_assignment
    if params[:id]
      @assignment = Assignment.find(params[:id]) 
    end

    if params[:course_id]
      @course = Course.find(params[:course_id])
    else
      @course = @assignment.course
    end
  end

  def assignment_params
    params[:assignment].permit(:name, :assignment, :due_date,
                               :points_available, :hide_grading, :blame_id,
                               :assignment_file, :grading_file, :solution_file,
                               :bucket_id, :course_id)
  end
end
