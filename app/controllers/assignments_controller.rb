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
    @assignment.due_date = (Time.now + 1.week).end_of_day.strftime("%Y/%m/%d %H:%M")
    @assignment.points_available = @course.assignments.order(created_at: :desc).first.points_available
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
    set_lateness_config

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
    set_lateness_config

    if @assignment.update_attributes(assignment_params)
      @assignment.save_uploads!
      redirect_to course_assignment_path(@course, @assignment), notice: 'Assignment was successfully updated.'
    else
      render action: "edit"
    end
  end

  def set_lateness_config
    lateness = params[:lateness]
    type = lateness[:type]
    lateness = lateness[type] unless lateness.nil? || type.nil?
    lateness[:type] = type
    if type == "UseCourseDefaultConfig"
      @assignment.lateness_config = @course.lateness_config
    elsif type != "reuse"
      late_config = LatenessConfig.new(lateness.permit(LatenessConfig.attribute_names - ["id"]))
      @assignment.lateness_config = late_config
      late_config.save
    end
  end

  def destroy
    unless current_user.site_admin? || current_user.registration_for(@course).professor?
      redirect_to root_path, alert: "Must be an admin or professor."
      return
    end

    @assignment = Assignment.find(params[:id])

    @assignment.destroy
    redirect_to @course, notice: "Assignment #{params[:id]} has been deleted."
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

  def tarball
    unless current_user.site_admin? || current_user.registration_for(@course).staff?
      redirect_to root_path, alert: "Must be an admin or staff."
      return
    end

    tb = SubTarball.new(params[:id])
    tb.update!
    redirect_to tb.path
  end

  def publish
    unless current_user.site_admin? || current_user.registration_for(@course).staff?
      redirect_to root_path, alert: "Must be an admin or staff."
      return
    end

    assignment = Assignment.find(params[:id])
    used = assignment.used_submissions
    used.each do |u|
      u.graders.update_all(:available => true)
    end

    redirect_to :back, notice: 'Grades successfully published'
  end

  def recreate_graders
    @course = Course.find(params[:course_id])
    @assignment = Assignment.find(params[:id])
    confs = @assignment.grader_configs.to_a
    count = @assignment.used_submissions.reduce(0) do |sum, sub|
      sum + sub.recreate_missing_graders(confs)
    end

    redirect_to :back, notice: "#{plural(count, 'grader')} created"
  end
    

  

  protected

  def assignment_params
    params[:assignment].permit(:name, :assignment, :due_date,
                               :points_available, :hide_grading, :blame_id,
                               :assignment_file, :grading_file, :solution_file,
                               :course_id, :team_subs)
  end
end
