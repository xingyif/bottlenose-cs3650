class RegRequestsController < ApplicationController
  before_filter :find_req_and_course
  before_filter :require_teacher, :except => [:new, :create]

  def index
    @reqs = @course.reg_requests
    @registration = Registration.new
  end

  def show    
  end

  def new
    @reg_request = RegRequest.new
    @reg_request.course_id = @course.id

    unless @logged_in_user.guest?
      @reg_request.name  = @logged_in_user.name
      @reg_request.email = @logged_in_user.email
    end
  end

  def edit
    redirect_to @reg_request, notice: 'No reason to edit'
  end

  def create
    @reg_request = RegRequest.new(params[:reg_request])
    @reg_request.course_id = @course.id

    if @reg_request.save
      @course.teachers.each do |teacher|
        NotificationMailer.got_reg_request(teacher, 
          @reg_request, root_url).deliver
      end

      redirect_to @course, notice: 'Request sent'
    else
      render action: "new"
    end
  end

  def update
    redirect_to @reg_request, notice: 'No reason to edit'
  end

  def destroy
    @reg_request.destroy
    redirect_to course_reg_requests_url(@course)
  end

  private

  def find_req_and_course
    if params[:id].nil?
      @course = Course.find(params[:course_id])
    else
      @reg_request = RegRequest.find(params[:id])
      @course      = @reg_request.course
    end
  end
end