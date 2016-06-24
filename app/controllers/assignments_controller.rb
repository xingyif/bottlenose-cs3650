class AssignmentsController < CoursesController

  def index
    raise "Not implemented."
  end

  def show
    @assignment = Assignment.find(params[:id])

    if current_user.site_admin? || current_user.registration_for(@course).staff?
      @submissions = @assignment.submissions.where(user_id: current_user.id)
    else
      @submissions = @assignment.submissions
    end
  end

  def new
    @course = Course.find(params[:course_id])
    bucket = @course.buckets.find_by_id(params[:bucket])

    @assignment = Assignment.new
    @assignment.course_id = @course.id
    @assignment.bucket = bucket
    @assignment.due_date = (Time.now + 1.month).to_date
    @assignment.points_available = 100
  end

  def edit
    @assignment = Assignment.find(params[:id])
  end

  def create
    @assignment = Assignment.new(assignment_params)
    @assignment.course_id = @course.id
    @assignment.blame_id = current_user.id

    if @assignment.save
      @assignment.save_uploads!
      redirect_to course_assignment_path(@course, @assignment), notice: 'Assignment was successfully created.'
    else
      render action: "new"
    end
  end

  def update
    if @assignment.update_attributes(assignment_params)
      @assignment.save_uploads!
      redirect_to course_assignment_path(@course, @assignment), notice: 'Assignment was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    @assignment.destroy
    show_notice "Assignment has been deleted."
    redirect_to @course
  end

  # TODO: There is no route for this currently.
  def tarball
    tb = SubTarball.new(@assignment.id)
    tb.update!
    redirect_to tb.path
  end

  protected

  def assignment_params
    params[:assignment].permit(:name, :assignment, :due_date,
                               :points_available, :hide_grading, :blame_id,
                               :assignment_file, :grading_file, :solution_file,
                               :bucket_id, :course_id, :team_subs)
  end
end
