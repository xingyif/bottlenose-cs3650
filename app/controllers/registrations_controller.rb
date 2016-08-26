require 'csv'

class RegistrationsController < CoursesController
  prepend_before_action :find_registration, except: [:index, :new, :create, :bulk]
  before_action :require_admin_or_staff, only: [:index, :create, :bulk, :destroy]
  
  def index
    @students = @course.students
    @staff = @course.staff
    @requests = @course.reg_requests.joins(:user).order('role desc', 'name').includes(:user)
  end

  def show
    unless current_user_prof_for?(@course) or current_user_has_id?(@registration.user.id)
      redirect_to @course, alert: "You don't have permission to access that page."
      return
    end

    @score = @registration.total_score
  end

  def new
    @registration = Registration.new
  end

  def create
    # Create @registration object for errors.
    @registration = Registration.new(registration_params)

    if params[:user_email].blank?
      @registration.errors[:base] << "Must provide an email."
      render action: "new"
      return
    end

    # Set the @registration to the new registration on @course.
    @registration = @course.add_registration(params[:user_email],
                                             @registration.role)

    if @registration.save
      redirect_to course_registrations_path(@course),
                  notice: 'Registration was successfully created.'
    else
      render action: :new
    end
  end

  def bulk
    @course = Course.find(params[:course_id])
    num_added = 0

    CSV.parse(params[:emails]) do |row|
      if @course.add_registration(row[0], row[1])
        num_added += 1
      end
    end

    redirect_to course_registrations_path(@course),
                notice: "Added #{num_added} students."
  end

  def destroy
    @registration.destroy

    redirect_to course_registrations_path(@course)
  end

  def submissions_for_assignment
    @assignment  = Assignment.find(params[:assignment_id])
    @submissions = @assignment.submissions_for(@user)
  end

  def toggle
    @registration.show_in_lists = ! @registration.show_in_lists?
    @registration.save

    @show = @registration.show_in_lists? ? "Yes" : "No"

    redirect_to back_or_else(course_registrations_path(@course))
  end

  private

  def find_registration
    @registration = Registration.find(params[:id])
    @course = @registration.course
    @user   = @registration.user
  end

  def registration_params
    params.require(:registration)
          .permit(:course_id, :role, :user_id, :show_in_lists, :tags)
  end

  def require_admin_or_staff
    unless current_user_site_admin? || current_user_staff_for?(@course)
      redirect_to back_or_else(root_path), alert: "Must be an admin or staff."
      return
    end
  end
end
