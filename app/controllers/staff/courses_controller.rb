require 'csv'

class Staff::CoursesController < Staff::BaseController
  before_action :find_course, except: [:index, :new, :create]

  before_filter :require_course_permission,
    except: [:index, :new, :create, :show, :public]
  before_filter :require_logged_in_user, except: [:public]
  before_filter :require_teacher,    only: [:export_grades, :edit, :update]
  before_filter :require_site_admin, only: [:new, :create, :destroy]

  def export_grades
    @subs = []
    @course.assignments.each do |assignment|
      assignment.main_submissions.each do |sub|
        @subs << sub
      end
    end

    render :formats => [:text]
  end

  def export_summary
    @buckets = @course.buckets
    @regs    = @course.active_registrations

    render :formats => [:text]
  end

  def bulk_add
    if request.post?
      num_added = 0

      if params[:emails]
        text = params[:emails]
        text.gsub!(/;,/, ' ')

        emails = text.split(/\s+/)
        emails.each do |ee|
          next unless ee =~ /\@.*\./
          prefix, _ = ee.split('@')
          @course.add_registration(prefix.downcase, ee)
          num_added += 1
        end
      end

      if params[:csv]
        csv = params[:csv]
        CSV.parse(csv.read) do |line|
          next unless line[1] =~ /\@.*\./
          @course.add_registration(line[0], line[1])
          num_added += 1
        end
      end

      flash[:notice] = "Added #{num_added} students."
    end
  end

  def index
    @courses_by_term = Course.order(:name).group_by(&:term)
  end

  def show
    @registration = current_user.registration_for(@course)
    @registration ||= "javascript:alert('Not registered.');"

    if current_user.course_admin?(@course)
      @active_regs = @course.active_registrations.
        sort_by {|rr| rr.user.invert_name.downcase }

      @req_count = @course.reg_requests.count

      @buckets = @course.buckets_sorted.to_a
      @scores, @totals = @course.score_summary
    end
  end

  def new
    @course = Course.new
    @terms = Term.all_sorted
  end

  def edit
    @terms = Term.all_sorted
  end

  def create
    @course = Course.new(course_params)
    @course.late_options = [params[:late_penalty], params[:late_repeat], params[:late_maximum]].join(',') unless params[:late_penalty].nil?

    if @course.save
      redirect_to staff_course_path(@course), notice: 'Course was successfully created.'
    else
      render action: "new"
    end
  end

  def update
    @course.assign_attributes(course_params)
    @course.late_options = [params[:late_penalty], params[:late_repeat], params[:late_maximum]].join(',') unless params[:late_penalty].nil?

    if @course.save
      redirect_to staff_course_path(@course), notice: 'Course was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    @course.destroy
    redirect_to staff_courses_path
  end

  private

  def find_course
    @course = Course.find(params[:id] || params[:course_id])
  end

  def course_params
    params[:course].permit(:name, :footer, :late_options, :private, :public,
                           :term_id, :sub_max_size)
  end
end
