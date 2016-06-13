class Staff::RegRequestsController < Staff::BaseController
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
end
