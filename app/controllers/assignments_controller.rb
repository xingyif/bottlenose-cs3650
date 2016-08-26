class AssignmentsController < CoursesController
  before_action :require_valid_course
  before_action :require_admin_or_prof, only: [:edit, :edit_weights, :update, :update_weights,
                                               :new, :create, :destroy,
                                               :recreate_graders]
  before_action :require_admin_or_staff, only: [:tarball, :publish]
  
  def show
    assignment = Assignment.find_by(id: params[:id])

    if current_user_site_admin? || current_user_staff_for?(@course)
      submissions = assignment.used_submissions.includes(:user).order(created_at: :desc).to_a
    elsif assignment.nil? or assignment.available > DateTime.now
      redirect_to back_or_else(course_assignments_path), alert: "No such assignment exists or is available"
      return
    else
      submissions = current_user.submissions_for(assignment).includes(:user).order(created_at: :desc).to_a
    end
    @gradesheet = Gradesheet.new(assignment, submissions)
  end

  def index
  end

  def new
    @assignment = Assignment.new
    @assignment.course_id = @course.id
    @assignment.due_date = (Time.now + 1.week).end_of_day.strftime("%Y/%m/%d %H:%M")
    last_assn = @course.assignments.order(created_at: :desc).first
    if last_assn
      @assignment.points_available = last_assn.points_available
    end
  end

  def edit
    @assignment = Assignment.find_by(id: params[:id])
    if @assignment.nil?
      redirect_to back_or_else(courses_assignments_path), alert: "No such assignment"
      return
    end
  end

  def edit_weights
  end

  def update_weights
    params[:weight].each do |kv|
      Assignment.find(kv[0]).update_attribute(:points_available, kv[1])
    end
    redirect_to course_assignments_path
  end
  
  def create
    @assignment = Assignment.new(assignment_params)
    @assignment.course_id = @course.id
    @assignment.blame_id = current_user.id

    if set_lateness_config and @assignment.save and set_grader_configs
      @assignment.save_uploads!
      redirect_to course_assignment_path(@course, @assignment), notice: 'Assignment was successfully created.'
    else
      render action: "new"
    end
  end

  def update
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
  
  def destroy
    @assignment = Assignment.find(params[:id])

    @assignment.destroy
    redirect_to @course, notice: "Assignment #{params[:id]} has been deleted."
  end

  def show_user
    if !current_user
      redirect_to back_or_else(root_path), alert: "Must be logged in"
      return
    elsif current_user_site_admin? || current_user_prof_for?(@course)
      # nothing
    elsif current_user.id != params[:user_id]
      redirect_to back_or_else(course_assignment_path(@course, @assignment)),
                  alert: "Not permitted to see submissions for other students"
    end
    
    @course = Course.find(params[:course_id])
    assignment = Assignment.find(params[:id])
    @user = User.find(params[:user_id])
    subs = @user.submissions_for(assignment)
    submissions = subs.select("submissions.*").includes(:users).order(created_at: :desc).to_a
    @gradesheet = Gradesheet.new(assignment, submissions)
  end

  def tarball
    tb = SubTarball.new(params[:id])
    tb.update!
    redirect_to tb.path
  end

  def publish
    assignment = Assignment.find(params[:id])
    used = assignment.used_submissions
    used.each do |u|
      u.graders.where(score: nil).each do |g| g.grader_config.grade(assignment, u) end
      u.graders.update_all(:available => true)
      u.compute_grade!
    end

    redirect_to back_or_else(course_assignment_path(@course, @assignment)),
                notice: 'Grades successfully published'
  end

  def recreate_graders
    @assignment = Assignment.find(params[:id])
    count = do_recreate_graders @assignment
    redirect_to back_or_else(course_assignment_path(@course, @assignment)),
                notice: "#{plural(count, 'grader')} created"
  end
    

  

  protected

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
    params_graders = graders_params
    if params_graders.nil?
      @assignment.errors.add(:graders, "parameter is missing")
      return false
    end

    no_problems = true
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
        no_problems = false
        next
      end
      type = type.split("_")[1]
      
      grader = grader[type]
      grader[:type] = type

      upload = grader[:upload_file]
      if upload
        up = Upload.new
        up.user_id = current_user.id
        up.store_upload!(upload, {
                           type: "#{type} Configuration",
                           date: Time.now.strftime("%Y/%b/%d %H:%M:%S %Z")
                         })
        unless up.save
          @assignment.errors.add(:upload_file, "could not save upload")
          no_problems = false
          next
        end
        grader[:upload_file] = up
      end
      
      graders[id] = grader
    end
    return no_problems unless no_problems


    GraderConfig.transaction do
      existing_confs = @assignment.grader_configs.to_a
      existing_ags = @assignment.assignment_graders.to_a
      max_order = existing_ags.reduce(0) do |acc, ag| [acc, ag.order].max end
      existing_confs.each do |c|
        conf = graders[c.id.to_s]
        graders.delete c.id.to_s
        if conf[:removed]
          existing_ags.find{|g| g.grader_config_id == c.id}.destroy
          next
        else
          c.assign_attributes(conf)
          if c.changed?
            unless c.save
              @assignment.errors << c.errors
              no_problems = false
              raise ActiveRecord::Rollback
            end
          end
        end
      end

      graders.each do |k, conf|
        next if conf[:removed]
        c = GraderConfig.new(conf)
        if c.invalid? or !c.save
          no_problems = false
          @assignment.errors.add(:graders, "Could not create grader #{c.to_s}")
          raise ActiveRecord::Rollback
        else
          AssignmentGrader.create!(assignment_id: @assignment.id, grader_config_id: c.id, order: max_order)
          max_order += 1
        end
      end

      # NOT SURE IF I WANT TO DO THIS IMMEDIATELY OR NOT
      # do_recreate_graders @assignment
    end

    return no_problems
  end

  def do_recreate_graders(assignment)
    confs = assignment.grader_configs.to_a
    count = @assignment.used_submissions.reduce(0) do |sum, sub|
      sum + sub.recreate_missing_graders(confs)
    end
    count
  end
  
  def assignment_params
    params[:assignment].permit(:name, :assignment, :due_date, :available,
                               :points_available, :hide_grading, :blame_id,
                               :assignment_file, 
                               :course_id, :team_subs)
  end

  def graders_params
    if params[:graders].nil?
      nil
    else
      params[:graders].map do |k, v|
        [k, v.permit([:id, :type, :removed,
                      :JavaStyleGrader => [:avail_score, :upload_file, :params, :type],
                      :CheckerGrader => [:avail_score, :upload_file, :params, :type],
                      :JunitGrader => [:avail_score, :upload_file, :params, :type],
                    :ManualGrader => [:avail_score, :upload_file, :params, :type]])]
      end.to_h
    end
  end

  def require_valid_course
    if @course.nil?
      redirect_to back_or_else(courses_path), alert: "No such course"
      return
    end
  end
  def require_admin_or_prof
    unless current_user_site_admin? || current_user_prof_for?(@course)
      redirect_to back_or_else(course_assignments_path), alert: "Must be an admin or professor."
      return
    end
  end
  def require_admin_or_staff
    unless current_user_site_admin? || current_user_staff_for?(@course)
      redirect_to root_path, alert: "Must be an admin or staff."
      return
    end
  end
end
