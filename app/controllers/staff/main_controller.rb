class Staff::MainController < Staff::BaseController
  # GET /staff
  def dashboard
    render "dashboard"
  end
end
