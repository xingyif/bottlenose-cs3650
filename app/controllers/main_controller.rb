class MainController < ApplicationController
  # GET /
  def home
    if current_user
      if current_user.sign_in_count == 1 and (current_user.profile == "" or current_user.nickname == "")
        debugger
        redirect_to edit_user_path(current_user),
                    notice: profile_notice
      else
        render "dashboard"
      end
    else
      render "landing"
    end
  end

  def resource_name
    :user
  end
  helper_method :resource_name

  def resource
    @resource ||= User.new
  end
  helper_method :resource

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end
  helper_method :devise_mapping

  # GET /about
  def about
  end

  protected

  def profile_notice
    <<NOTICE.html_safe
Please complete your user profile, so we can recognize you in class: 
<ul>
<li>Please give us a <i>recognizable</i> profile picture</li>
<li>Please fill in your preferred nickname</li>
<li>Please make sure you can receive email at the specified address</li>
</ul>
NOTICE
  end
end
