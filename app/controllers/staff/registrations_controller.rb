require 'csv'

class Staff::RegistrationsController < Staff::BaseController
  before_filter :require_teacher, :except => [:show, :submissions_for_assignment]
  before_filter :require_course_permission
  prepend_before_filter :find_registration,
                        except: [:index, :new, :create, :bulk]

  def index
    @registration = Registration.new(course_id: @course.id)
  end

  def show
    unless current_user.course_admin?(@course) or @registration.user.id == current_user.id
      show_error "I can't let you do that."
      redirect_to @course
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

    if params[:user_name].blank? || params[:user_email].blank?
      @registration.errors[:base] << "Must provide both name and email."
      render action: "new"
      return
    end

    # Set the @registration to the new registration on @course.
    @registration = @course.add_registration(params[:user_name],
                                             params[:user_email],
                                             @registration.teacher?)

    if @registration.save
      redirect_to staff_course_registrations_path(@course),
                  notice: 'Registration was successfully created.'
    else
      render action: :new
    end
  end

  def bulk
    @course = Course.find(params[:course_id])
    num_added = 0

    CSV.parse(params[:emails]) do |row|
      email = row[0]
      if email =~ /\@.*\./
        name, _ = email.split('@')
        @course.add_registration(name.downcase, email)
        num_added += 1
      end
    end

    redirect_to staff_course_registrations_path(@course),
                notice: "Added #{num_added} students."
  end

  def update
    if @registration.update_attributes(registration_params)
      redirect_to [:edit, @registration],
        notice: 'Registration was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    @registration.destroy

    redirect_to course_registrations_path(@course)
  end

  def submissions_for_assignment
    @assignment  = Assignment.find(params[:assignment_id])
    @submissions = @assignment.submissions_for(@user)
  end

  def toggle_show
    @registration.show_in_lists = ! @registration.show_in_lists?
    @registration.save

    @show = @registration.show_in_lists? ? "Yes" : "No"
  end

  private

  def find_registration
    @registration = Registration.find(params[:id])
    @course = @registration.course
    @user   = @registration.user
  end

  def registration_params
    params.require(:registration)
          .permit(:course_id, :teacher, :user_id, :show_in_lists, :tags)
  end
end
