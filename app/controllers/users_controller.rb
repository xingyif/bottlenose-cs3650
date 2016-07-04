class UsersController < ApplicationController
  def index
    unless current_user.site_admin?
      redirect_to root_path, alert: "Must be an admin"
      return
    end

    @users = User.order(:name)
    @user  = User.new
  end

  def show
    unless current_user.site_admin?
      redirect_to root_path, alert: "Must be an admin"
      return
    end

    @user = User.find(params[:id])
  end

  def edit
    unless current_user.site_admin?
      redirect_to root_path, alert: "Must be an admin"
      return
    end

    @user = User.find(params[:id])
  end

  def update
    unless current_user.site_admin?
      redirect_to root_path, alert: "Must be an admin"
      return
    end

    @user = User.find(params[:id])

    if @user.update_attributes(user_params)
      if current_user.site_admin?
        redirect_to user_path(@user), notice: 'User was successfully updated.'
      else
        redirect_to '/courses', notice: "Name successfully updated"
      end
    else
      if current_user.site_admin?
        render action: "edit"
      else
        redirect_to '/main/auth',
          alert: "Error updating name: #{@user.errors.full_messages.join('; ')}"
      end
    end
  end

  def destroy
    unless current_user.site_admin?
      redirect_to root_path, alert: "Must be an admin"
      return
    end

    @user = User.find(params[:id])
    @user.destroy

    redirect_to users_path
  end

  def impersonate
    unless current_user.site_admin?
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
    if current_user && current_user.site_admin?
      params[:user].permit(:email, :name, :site_admin)
    else
      params[:user].permit(:email, :name)
    end
  end
end
