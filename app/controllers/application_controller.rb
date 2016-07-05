class ApplicationController < ActionController::Base
  impersonates :user

  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end
  protect_from_forgery

  before_filter :set_mailer_host
  before_filter :configure_permitted_parameters, if: :devise_controller?

  # # Ensure we have a `current_user` for all actions by default. Controllers
  # # must manually opt out of this if they wish to be public.
  # before_filter :require_current_user
  # # Allow devise actions for users without active sessions.
  # skip_before_filter :require_current_user, if: :devise_controller?

  protected

  def set_mailer_host
    ActionMailer::Base.default_url_options[:host] = request.host_with_port
    ActionMailer::Base.default_url_options[:protocol] = request.protocol
  end

  def find_course
    if params[:course_id].nil?
      @course ||= Course.find(params[:id])
    else
      @course ||= Course.find(params[:course_id])
    end
  end

  # TODO: Delete.
  def show_notice(msg)
    flash[:notice] = msg
  end
  deprecate :show_notice

  # TODO: Delete.
  def show_error(msg)
    flash[:error] = msg
  end
  deprecate :show_error

  # Require that there is a `current_user` indicating that a user is currently
  # logged in.
  def require_current_user
    if current_user.nil?
      msg = "You need to log in first."
      redirect_to root_path, alert: msg
      return
    end
  end

  # Require that the `current_user` is a site admin.
  def require_site_admin
    unless current_user && current_user.site_admin?
      msg = "You don't have permission to access that page."
      redirect_to root_path, alert: msg
      return
    end
  end

  #
  # def require_student
  #   find_course
  #
  #   if current_user.nil?
  #     show_error "You need to register first"
  #     redirect_to '/'
  #     return
  #   end
  #
  #   if @course.nil?
  #     show_error "No such course."
  #     redirect_to courses_url
  #     return
  #   end
  #
  #   if current_user.site_admin?
  #     return
  #   end
  #
  #   reg = current_user.registrations.where(course_id: @course.id)
  #
  #   if reg.nil? or reg.empty?
  #     show_error "You're not registered for that course."
  #     redirect_to courses_url
  #     return
  #   end
  # end
  #
  # def require_staff
  #   find_course
  #
  #   if current_user.nil?
  #     show_error "You need to register first"
  #     redirect_to '/'
  #     return
  #   end
  #
  #   if @course.nil?
  #     show_error "No such course."
  #     redirect_to courses_url
  #     return
  #   end
  #
  #   unless current_user.site_admin? or @course.taught_by?(current_user)
  #     show_error "You're not allowed to go there."
  #     redirect_to course_url(@course)
  #     return
  #   end
  # end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) do |user|
      user.permit(:name, :email, :password, :password_confirmation)
    end
  end
end
