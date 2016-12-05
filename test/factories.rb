
FactoryGirl.define do
  sequence :user_name do |n|
    letters = ('A'..'Z').to_a
    first = letters[(n * 17) % 26] + "#{n}"
    last  = letters[(n * 13) % 26] + "#{n}"
    "#{first} #{last}"
  end

  factory :user do
    name  { generate(:user_name) }
    password "password"
    username { name.downcase.gsub(/\W/, '_') }
    email { username + "@example.com" }
    site_admin false

    factory :admin_user do
      site_admin true
    end
  end

  factory :term do
    sequence(:name) {|n| "Fall #{2010 + n}" }
    archived false
  end

  factory :lateness_config do
    type "LatePerDayConfig"
    days_per_assignment 365
    percent_off 50
    frequency 1
    max_penalty 100
  end

  factory :course do
    term
    lateness_config

    sequence(:name) {|n| "Computing #{n}" }
    footer "Link to Piazza: *Link*"
  end

  factory :course_section do
    course
    sequence(:crn) {|n| 1000 + n }
    sequence(:meeting_time) {|n| "Tuesday #{n}:00" }
    association :instructor, factory: :user
  end

  factory :grader_config do
    type "ManualGrader"
    avail_score 100.0
    params ""
  end

  factory :assignment_grader do
    grader_config
    assignment
    order 0
  end

  factory :assignment do
    course
    association :blame, factory: :user
    lateness_config
    available (Time.now - 10.days)
    points_available 100

    sequence(:name) {|n| "Homework #{n}" }
    due_date (Time.now + 7.days)
  end

  factory :upload do
    user

    file_name "none"
    secret_key { SecureRandom.hex }
  end

  factory :submission do
    assignment
    user
    upload

    after(:build) do |sub|
      unless sub.user.registration_for(sub.course)
        create(:registration, user: sub.user, course: sub.course)
      end

      if sub.upload
        sub.upload.user_id = sub.user_id
      end
    end
  end

  factory :registration do
    user
    course
    association :section, factory: :course_section

    role 0
    show_in_lists true
  end

  factory :reg_request do
    user
    course
    association :section, factory: :course_section

    notes "Let me in!"
  end

  factory :team do
    course

    after(:build) do |team|
      u1 = create(:user)
      u2 = create(:user)

      r1 = create(:registration, user: u1, course: team.course)
      r2 = create(:registration, user: u2, course: team.course)

      team.users = [u1, u2]
      team.start_date = Time.now - 2.days
    end
  end
end

