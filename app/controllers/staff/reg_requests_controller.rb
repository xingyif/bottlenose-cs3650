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

  def reject
    RegRequest.find(params[:id]).destroy
    redirect_to :back
  end
end
