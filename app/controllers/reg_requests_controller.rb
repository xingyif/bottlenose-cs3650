class RegRequestsController < CoursesController
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

    if Registration.create(user: @request.user,
                           course: @request.course,
                           role: @request.role,
                           show_in_lists: @request.role == :student)
      @request.destroy
      redirect_to :back
    end
  end

  def reject
    RegRequest.find(params[:id]).destroy
    redirect_to :back
  end

  private

  def reg_request_params
    params[:reg_request].permit(:notes, :role)
  end
end
