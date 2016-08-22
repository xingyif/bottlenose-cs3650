class AssignmentsController < CoursesController
  def show
    assignment = Assignment.find(params[:id])

    if current_user_site_admin? || current_user_staff_for?(@course)
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
    unless current_user_site_admin? || current_user_prof_for?(@course)
      redirect_to :back, alert: "Must be an admin or professor."
      return
    end
  end

  def update_weights
    unless current_user_site_admin? || current_user_prof_for?(@course)
      redirect_to :back, alert: "Must be an admin or professor."
      return
    end
    params[:weight].each do |kv|
      Assignment.find(kv[0]).update_attribute(:points_available, kv[1])
    end
    redirect_to course_assignments_path
  end
  
  def create
    unless current_user_site_admin? || current_user_prof_for?(@course)
      redirect_to root_path, alert: "Must be an admin or professor."
      return
    end

    @assignment = Assignment.new(assignment_params)
    @assignment.course_id = @course.id
    @assignment.blame_id = current_user.id
    unless set_lateness_config and set_grader_configs
      render action: "new"
      return
    end

    if @assignment.save
      @assignment.save_uploads!
      redirect_to course_assignment_path(@course, @assignment), notice: 'Assignment was successfully created.'
    else
      render action: "new"
    end
  end

  def update
    unless current_user_site_admin? || current_user_prof_for?(@course)
      redirect_to root_path, alert: "Must be an admin or professor."
      return
    end

    @assignment = Assignment.find(params[:id])
    unless set_lateness_config and set_grader_configs
      render action: "edit"
      return
    end

    if @assignment.update_attributes(assignment_params)
      @assignment.save_uploads!
      redirect_to course_assignment_path(@course, @assignment), notice: 'Assignment was successfully updated.'
    else
      render action: "edit"
    end
  end

  def set_lateness_config
    lateness = params[:lateness]
    if lateness.nil?
      @assignment.errors.add(:lateness, "Lateness parameter is missing")
      return false
    end
      
    type = lateness[:type]
    if type.nil?
      @assignment.errors.add(:lateness, "Lateness type is missing")
      return false
    end
    type = type.split("_")[1]
    
    lateness = lateness[type]
    lateness[:type] = type
    if type == "UseCourseDefaultConfig"
      @assignment.lateness_config = @course.lateness_config
    elsif type != "reuse"
      late_config = LatenessConfig.new(lateness.permit(LatenessConfig.attribute_names - ["id"]))
      @assignment.lateness_config = late_config
      late_config.save
    end
    return true
  end

  def set_grader_configs
    params_graders = params[:graders]
    if params_graders.nil?
      @assignment.errors.add(:graders, "parameter is missing")
      return false
    end

    problems = false
    graders = {}
    params_graders.each do |id, grader|
      grader[:removed] = true if grader[:removed] == "true"
      grader[:removed] = false if grader[:removed] == "false"
      if grader[:removed]
        graders[id] = grader
        next
      end
      
      type = grader[:type]
      if type.nil?
        @assignment.errors.add(:graders, "type is missing")
        problems = true
        next
      end
      type = type.split("_")[1]
      
      grader = grader[type]
      grader[:type] = type
      graders[id] = grader
    end
    return problems if problems

    existing_confs = @assignment.grader_configs.to_a
    to_remove = existing_confs.select do |c|
      ans = false
      conf = graders[c.id.to_s]
      ans = true if conf[:removed]
      ans = true if conf[:type] != c.type
      ans = true if conf[:avail_score].to_f != c.avail_score
      ans
    end
    
    debugger
    return problems
  end
  
  def destroy
    unless current_user_site_admin? || current_user_prof_for?(@course)
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
    elsif current_user_site_admin? || current_user_prof_for?(@course)
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
    unless current_user_site_admin? || current_user_staff_for?(@course)
      redirect_to root_path, alert: "Must be an admin or staff."
      return
    end

    tb = SubTarball.new(params[:id])
    tb.update!
    redirect_to tb.path
  end

  def publish
    unless current_user_site_admin? || current_user_staff_for?(@course)
      redirect_to root_path, alert: "Must be an admin or staff."
      return
    end

    assignment = Assignment.find(params[:id])
    used = assignment.used_submissions
    used.each do |u|
      u.graders.where(score: nil).each do |g| g.grader_config.grade(assignment, u) end
      u.graders.update_all(:available => true)
      u.compute_grade!
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
                               :assignment_file, 
                               :course_id, :team_subs)
  end
end
