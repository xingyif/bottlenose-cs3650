class Staff::UsersController < Staff::BaseController
  # skip_before_action :require_staff, only: :stop_impersonating
  # before_action :require_site_admin, except: [:new, :create, :update, :stop_impersonating]

  def index
    @users = User.order(:name)
    @user  = User.new
  end

  def show
    @user = User.find(params[:id])
  end

  def new
    @user = User.new
    @terms = Term.all
  end

  def edit
    @user = User.find(params[:id])
  end

  def create
    @user = User.new(user_params)

    if User.count == 0
      @user.site_admin = true
    else
      @user.site_admin = false
    end

    if @user.save
      @user.send_auth_link_email!

      if current_user.nil?
        redirect_to '/',
          notice: 'User created. Check your email for an authentication link.'
      else
        redirect_to @user, notice: 'User was successfully created.'
      end
    else
      render action: "new"
    end
  end

  def update
    @user = User.find(params[:id])

    if @user.update_attributes(user_params)
      if current_user.site_admin?
        redirect_to staff_user_path(@user), notice: 'User was successfully updated.'
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
    @user = User.find(params[:id])
    @user.destroy

    redirect_to staff_users_path
  end

  def impersonate
    @user = User.find(params[:id])
    impersonate_user(@user)
    redirect_to root_path, notice: "You are impersonating #{@user.name}."
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
