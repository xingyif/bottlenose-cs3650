class RegRequestsController < CoursesController
  skip_before_action :load_and_verify_course_registration

  # GET /courses/:course_id/reg_requests/new
  def new
    @course = Course.find(params[:course_id])
    @reg_request = @course.reg_requests.new
  end

  # POST /courses/:course_id/reg_requests
  def create
    @course = Course.find(params[:course_id])
    @reg_request = @course.reg_requests.new(reg_request_params)
    @reg_request.user = current_user

    if @reg_request.save
      @course.professors.each do |teacher|
        NotificationMailer.got_reg_request(teacher,
          @reg_request, root_url).deliver_later
      end

      redirect_to courses_path, notice: 'A registration request will be sent.'
    else
      render :new
    end
  end

  def accept
    @request = RegRequest.find(params[:id])
    errs = accept_help(@request)
    if errs
      redirect_to :back, alert: errs
    else
      redirect_to :back
    end
  end

  def accept_all
    count = 0
    RegRequest.where(course_id: params[:course_id]).each do |req|
      errs = accept_help(req)
      if errs
        redirect_to :back, alert: errs
        return
      end
      count = count + 1
    end
    redirect_to :back, notice: "#{plural(count, 'registration')} added"
  end

  def accept_help(request)
    begin
      reg = Registration.find_or_create_by(user: request.user,
                                           course: request.course,
                                           role: request.role,
                                           section: request.section.crn)
      if reg
        reg.show_in_lists = (request.role == :student)
        reg.dropped_date = nil
        reg.save!
        request.destroy
      end
      nil
    rescue Exception => err
      debugger
      err.record.errors
    end
  end
  

  def reject
    RegRequest.find(params[:id]).delete
    redirect_to :back
  end

  def reject_all
    RegRequest.where(course_id: params[:course_id]).delete_all # No dependents, so deletion is fine
    redirect_to :back
  end

  private

  def reg_request_params
    ans = params[:reg_request].permit(:notes, :role, :section)
    ans[:section] = CourseSection.find_by(crn: ans[:section].to_i)
    ans
  end
end
