class Staff::BaseController < ApplicationController
  # TODO: What exactly should we verify here?
  before_filter :require_staff

  protected

  def require_staff
    if current_user.nil?
      show_error "You must be logged in as a staff member to view this page."
      redirect_to root_path
      return
    end
  end
end
