class AssignmentsController < CoursesController
  def show
    assignment = Assignment.find(params[:id])

    if current_user.site_admin? || current_user.registration_for(@course).staff?
      submissions = assignment.used_submissions.includes(:user).order(created_at: :desc).to_a
    else
      submissions = current_user.submissions_for(assignment).includes(:user).order(created_at: :desc).to_a
    end
    @gradesheet = Gradesheet.new(assignment, submissions)
  end

  def index
  end

  def new
    @course = Course.find(params[:course_id])

    @assignment = Assignment.new
    @assignment.course_id = @course.id
    @assignment.due_date = (Time.now + 1.month).to_date
    @assignment.points_available = 100
  end

  def edit
    @assignment = Assignment.find(params[:id])
  end

  def edit_weights
    unless current_user.site_admin? || current_user.registration_for(@course).professor?
      redirect_to :back, alert: "Must be an admin or professor."
      return
    end
  end

  def update_weights
    unless current_user.site_admin? || current_user.registration_for(@course).professor?
      redirect_to :back, alert: "Must be an admin or professor."
      return
    end
    params[:weight].each do |kv|
      Assignment.find(kv[0]).update_attribute(:points_available, kv[1])
    end
    redirect_to course_assignments_path
  end
  
  def create
    unless current_user.site_admin? || current_user.registration_for(@course).professor?
      redirect_to root_path, alert: "Must be an admin or professor."
      return
    end

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
    unless current_user.site_admin? || current_user.registration_for(@course).professor?
      redirect_to root_path, alert: "Must be an admin or professor."
      return
    end

    @assignment = Assignment.find(params[:id])

    if @assignment.update_attributes(assignment_params)
      @assignment.save_uploads!
      redirect_to course_assignment_path(@course, @assignment), notice: 'Assignment was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    unless current_user.site_admin? || current_user.registration_for(@course).professor?
      redirect_to root_path, alert: "Must be an admin or professor."
      return
    end

    @assignment = Assignment.find(params[:id])

    @assignment.destroy
    show_notice "Assignment has been deleted."
    redirect_to @course
  end

  def show_user
    if !current_user
      redirect_to :back, alert: "Must be logged in"
      return
    elsif current_user.site_admin? || current_user.registration_for(@course).professor?
      # nothing
    elsif current_user.id != params[:user_id]
      redirect_to :back, alert: "Not permitted to see submissions for other students"
    end
    
    @course = Course.find(params[:course_id])
    assignment = Assignment.find(params[:id])
    @user = User.find(params[:user_id])
    subs = @user.submissions_for(assignment)
    submissions = subs.select("submissions.*").includes(:users).order(created_at: :desc).to_a
    @gradesheet = Gradesheet.new(assignment, submissions)
  end

  # TODO: There is no route for this currently.
  def tarball
    unless current_user.site_admin? || current_user.registration_for(@course).staff?
      redirect_to root_path, alert: "Must be an admin or staff."
      return
    end

    tb = SubTarball.new(params[:id])
    tb.update!
    redirect_to tb.path
  end

  protected

  def assignment_params
    params[:assignment].permit(:name, :assignment, :due_date,
                               :points_available, :hide_grading, :blame_id,
                               :assignment_file, :grading_file, :solution_file,
                               :course_id, :team_subs)
  end
end
