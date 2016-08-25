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

  # Require that there is a `current_user` indicating that a user is currently
  # logged in.
  def require_current_user
    if current_user.nil?
      msg = "You need to log in first."
      redirect_to root_path, alert: msg
      return
    end
  end

  def current_user_site_admin?
    current_user && current_user.site_admin?
  end
  def current_user_prof_ever?
    current_user && current_user.professor_ever?
  end
  def current_user_prof_for?(course)
    current_user && (current_user.site_admin? || current_user.registration_for(course).professor?)
  end
  def current_user_staff_for?(course)
    current_user && (current_user.site_admin? || current_user.registration_for(course).staff?)
  end
  def true_user_prof_for?(course)
    true_user && (true_user.site_admin? || true_user.registration_for(course).professor?)
  end
  def true_user_staff_for?(course)
    true_user && (true_user.site_admin? || true_user.registration_for(course).staff?)
  end
  def current_user_has_id?(id)
    current_user && current_user.id == id
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) do |user|
      user.permit(:name, :email, :username, :password, :password_confirmation)
    end
  end
end
