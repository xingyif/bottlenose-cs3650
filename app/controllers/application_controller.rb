class ApplicationController < ActionController::Base
  impersonates :user

  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end
  protect_from_forgery

  before_action :set_mailer_host
  before_action :configure_permitted_parameters, if: :devise_controller?

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
  def require_valid_course
    if @course.nil?
      redirect_to back_or_else(courses_path), alert: "No such course"
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


  def back_or_else(target)
    if request.env["HTTP_REFERER"].present? and request.env["HTTP_REFERER"] != request.env["REQUEST_URI"]
      :back
    else
      target
    end
  end

  def array_from_hash(h)
    return h unless h.is_a? Hash

    all_numbers = h.keys.all? { |k| k.to_i.to_s == k }
    if all_numbers
      ans = []
      h.keys.sort_by{ |k| k.to_i }.map{ |i| ans[i.to_i] = array_from_hash(h[i]) }
      ans
    else
      ans = {}
      h.each do |k, v|
        ans[k] = array_from_hash(v)
      end
      ans
    end
  end
end
