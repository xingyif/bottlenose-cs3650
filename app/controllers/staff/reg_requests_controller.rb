class Staff::RegRequestsController < Staff::BaseController
  def accept
    @request = RegRequest.find(params[:id])

    if Registration.create(user: @request.user,
                           course: @request.course,
                           teacher: false,
                           show_in_lists: true)
      @request.destroy
      redirect_to :back
    end
  end

  def accept_all
    @course = Course.find(params[:course_id])

    @course.reg_requests.each do |request|
      if Registration.create(user: request.user,
                             course: request.course,
                             teacher: false,
                             show_in_lists: true)
        request.destroy
      end
    end

    redirect_to :back
  end

  def reject
    RegRequest.find(params[:id]).destroy
    redirect_to :back
  end

  def reject_all
    @course = Course.find(params[:course_id])
    @course.reg_requests.each(&:destroy)

    redirect_to :back
  end
end
