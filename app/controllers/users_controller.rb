class UsersController < ApplicationController
  def index
    unless current_user_site_admin?
      redirect_to root_path, alert: "Must be an admin"
      return
    end

    @users = User.order(:name)
    @user  = User.new
  end

  def show
    unless current_user_site_admin? || current_user_has_id?(params[:id].to_i)
      redirect_to root_path, alert: "Must be an admin"
      return
    end

    @user = User.find(params[:id])
  end

  def edit
    unless current_user_site_admin? || current_user_has_id?(params[:id].to_i)
      redirect_to root_path, alert: "Must be an admin"
      return
    end

    @user = User.find(params[:id])
  end

  def update
    unless current_user_site_admin? || current_user_has_id?(params[:id].to_i)
      redirect_to root_path, alert: "Must be an admin"
      return
    end

    @user = User.find(params[:id])

    up = user_params

    if @user.profile && File.exists?(@user.profile) && up[:profile]
      FileUtils.rm(@user.profile)
      @user.profile = nil
    end
    if up[:profile]
      image = up[:profile]
      secret = SecureRandom.urlsafe_base64
      filename = Upload.base_upload_dir.join("#{secret}_#{image.original_filename}")
      File.open(filename, "wb") do |f| f.write(image.read) end
      up[:profile] = filename.to_s
    end
    
    if @user.update_attributes(up)
      if current_user_site_admin?
        redirect_to user_path(@user), notice: 'User was successfully updated.'
      else
        redirect_to '/courses', notice: "Profile successfully updated"
      end
    else
      if current_user_site_admin?
        render action: "edit"
      else
        redirect_to '/main/auth',
          alert: "Error updating name: #{@user.errors.full_messages.join('; ')}"
      end
    end
  end

  def destroy
    unless current_user_site_admin?
      redirect_to root_path, alert: "Must be an admin"
      return
    end

    if self.profile && File.exists?(self.profile)
      FileUtils.rm self.profile
    end

    @user = User.find(params[:id])
    @user.destroy

    redirect_to users_path
  end

  def impersonate
    unless current_user_site_admin?
      redirect_to root_path, alert: "Must be an admin"
      return
    end

    @user = User.find(params[:id])
    impersonate_user(@user)
    redirect_to root_path, notice: "You are impersonating #{@user.display_name}."
  end

  def stop_impersonating
    stop_impersonating_user
    redirect_to root_path, notice: "You are not impersonating anyone anymore."
  end

  private

  def user_params
    if current_user_site_admin?
      params[:user].permit(:email, :name, :nickname, :first_name, :last_name, :nuid, :profile, :site_admin)
    else
      params[:user].permit(:email, :name, :nickname, :first_name, :last_name, :nuid, :profile)
    end
  end
end
