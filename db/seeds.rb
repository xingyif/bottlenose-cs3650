require 'devise/encryptor'

[Course, Bucket, Assignment, Registration].each do |model|
  model.reset_column_information
end

def random(arr)
  arr[rand(arr.count)]
end

case Rails.env
when "development"
  # Create four users.
  ben = User.create!(
                     username: "blerner",
                     name: "Benjamin Lerner",
                     first_name: "Benjamin",
                     last_name: "Lerner",
                     nickname: "Ben",
                     site_admin: true,
                     )
  justin = User.create!(
                        email: "justin.case@fallback.ccs.neu",
                        username: "justin.case@fallback.ccs.neu",
                        name: "Justin Case",
                        first_name: "Justin",
                        last_name: "Case",
                        nickname: "Safetynet",
                        )
  justin.encrypted_password = Devise::Encryptor.digest(justin.class, "planet of the O0d")
  justin.save!

  olin = User.create!(
                      username: "shivers",
                      name: "Olin Shivers",
                      first_name: "Olin",
                      last_name: "Shivers"
                      )
  amal = User.create!(
                      username: "amal",
                      name: "Amal Ahmed",
                      first_name: "Amal",
                      last_name: "Ahmed"
                      )

  fixed_lateness = FixedDaysConfig.create!(days_per_assignment: 2)
  pct_lateness = LatePerDayConfig.create!(percent_off: 25, frequency: 1, days_per_assignment: 4, max_penalty: 100)
  
  # Create two terms.
  fall = Term.create!(name: "Fall 2015")
  spring = Term.create!(name: "Spring 2016")

  # The first course.
  fundies1 = Course.create!(
                            name: "Fundamentals of Computer Science 1",
                            term: fall,
                            lateness_config: fixed_lateness,
                            total_late_days: nil
  )

  fundies_sections = [
    CourseSection.create!(course: fundies1,
                          crn: 12345,
                          instructor: ben,
                          meeting_time: "MWTh 3:30--4:50"
                           ),
    CourseSection.create!(course: fundies1,
                          crn: 87654,
                          instructor: amal,
                          meeting_time: "MWTh 10:30--11:45"
                         )
  ]
  
  0.upto(5).each do |i|
    assignment = Assignment.create!(
                                    name: "Homework #{i}",
                                    assignment: "This is an example homework assignment, don't try to actually do this.",
                                    course: fundies1,
                                    team_subs: i < 3,
                                    points_available: 7.5,
                                    lateness_config: (i % 2 == 1) ? pct_lateness : fundies1.lateness_config,
                                    blame: ben,
                                    available: Time.now + ((i - 4) * 1.week),
                                    due_date: Time.now + ((i - 3) * 1.week),
                                    )
    if i == 2
      testfile = File.new("#{Rails.root}/hw2/hw2.tgz")
      testfile = ActionDispatch::Http::UploadedFile.new(filename: File.basename(testfile),
                                                        tempfile: testfile)
      up = Upload.new
      up.user_id = ben.id
      up.store_upload!(testfile, {type: "Junit Configuration", date: Time.now.strftime("%Y/%b/%d %H:%M:%S %Z")})
      up.save
      junit = JunitGrader.new({avail_score: 58, params: "Grade03resubmit", upload_file: up})
      junit.save
      AssignmentGrader.create!(assignment_id: assignment.id, grader_config_id: junit.id, order: 1)
    elsif i == 3
      testfile = File.new("#{Rails.root}/hw3/hw03_p1_tests.java")
      testfile = ActionDispatch::Http::UploadedFile.new(filename: File.basename(testfile),
                                                        tempfile: testfile)
      up = Upload.new
      up.user_id = ben.id
      up.store_upload!(testfile, {type: "Checker Configuration", date: Time.now.strftime("%Y/%b/%d %H:%M:%S %Z")})
      up.save
      checker = CheckerGrader.new({avail_score: 64, params: "ExamplesStringsReference", upload_file: up})
      checker.save
      AssignmentGrader.create!(assignment_id: assignment.id, grader_config_id: checker.id, order: 1)
    end
    style = JavaStyleGrader.create!(avail_score: 55)
    AssignmentGrader.create!(assignment_id: assignment.id, grader_config_id: style.id, order: 2)
    manual = ManualGrader.create!(avail_score: 42)
    AssignmentGrader.create!(assignment_id: assignment.id, grader_config_id: manual.id, order: 3)
  end

  questionnaire = Questionnaire.create!(name: "Self-eval for #{Assignment.first.name}",
                                        assignment: Assignment.first,
                                        available_date: Assignment.first.due_date,
                                        due_date: Assignemnt.first.due_date + 1.day,
                                        course: fundies1,
                                        lateness_config: fundies1.lateness_config,
                                        blame: ben,
                                        points_available: 10,
                                        max_attempts: 3,
                                        team_subs: Assignment.first.team_subs)
  qtypes = {
    "MultipleChoiceQuestion" => "yes/no/maybe/don't care",
    "NumericQuestion" => "0.0:1.5",
    "YesNoQuestion"=> "",
    "TrueFalseQuestion" => "",
    "FreeTextQuestion" => "",
    "CodeReferenceQuestion" => ""
  }
  qtypes.each_with_index do |qtype, options, i|
    Question.create!(questionnaire: questionnaire,
                     type: qtype,
                     prompt: "This is question #{i} -- what do you think?",
                     weight: i,
                     options: options)
  end
  
  [ben, olin, amal].each do |professor|
    Registration.create!(
                         user: professor,
                         course: fundies1,
                         section: fundies_sections[0],
                         role: :professor,
                         show_in_lists: false,
                         )
  end
  students = 1.upto(20).map do |i|
    user = User.create!(
                        email: "user#{i}@example.com",
                        username: "user#{i}@example.com",
                        name: "User #{i}",
                        )
    Registration.create!(
                         user: user,
                         course: fundies1,
                         role: :student,
                         section: random(fundies_sections),
                         show_in_lists: true,
                         )
    user
  end

  1.upto(students.count / 2).each do |i|
    Team.create!(
                 course_id: fundies1.id,
                 start_date: Date.current,
                 created_at: DateTime.current,
                 updated_at: DateTime.current,
                 users: [students[i - 1], students[i + (students.count / 2) - 1]]
                 )
  end

  subs = ["#{Rails.root}/hw1/strings.rkt",
          "#{Rails.root}/hw2/grading/cs3500.tar.gz",
          "#{Rails.root}/hw3/Strings.java"]
    
  fundies1.assignments.each do |assignment|
    if assignment.team_subs?
      print "Creating team submissions for #{fundies1.students.count} students in #{assignment.name}\n"
      fundies1.students.each do |student|
        upload = Upload.new
        submit_time = assignment.due_date + 48.hours - rand(96).hours
        upload.user_id = student.id
        submission_file = File.new(random(subs))
        upload.store_upload!(
          ActionDispatch::Http::UploadedFile.new(filename: File.basename(submission_file),
                                                 tempfile: submission_file
                                                ),
          
          {
            type:       "Team Submission File",
            user:       "#{student.name} (#{student.id})",
            course:     "#{assignment.course.name} (#{assignment.course.id})",
            date:       submit_time.strftime("%Y/%b/%d %H:%M:%S %Z")
          })
        upload.save!
        
        team = student.active_team_for(fundies1)
        sub = Submission.create!(
                                 upload_id: upload.id,
                                 student_notes: "A team effort",
                                 assignment_id: assignment.id,
                                 user: student,
                                 team: team,
                                 created_at: submit_time,
                                 )
        sub.autograde!
        sub.set_used_sub!
      end
    else
      print "Creating individual submissions for #{fundies1.students.count} students in #{assignment.name}\n"
      fundies1.students.each do |student|
        upload = Upload.new
        submit_time = assignment.due_date + 48.hours - rand(96).hours
        upload.user_id = student.id
        submission_file = File.new(random(subs))
        upload.store_upload!(
          ActionDispatch::Http::UploadedFile.new(filename: File.basename(submission_file),
                                                 tempfile: submission_file,
                                                ),
          {
            type:       "Submission File",
            user:       "#{student.name} (#{student.id})",
            course:     "#{assignment.course.name} (#{assignment.course.id})",
            date:       submit_time.strftime("%Y/%b/%d %H:%M:%S %Z")
          })
        upload.save!

        sub = Submission.create!(
                                 upload_id: upload.id,
                                 student_notes: "A submission",
                                 assignment_id: assignment.id,
                                 user: student,
                                 created_at: submit_time
                                 )
        sub.autograde!
        sub.set_used_sub!
      end
    end
  end
when "production"
  ben = User.create!(
                     username: "blerner",
                     name: "Benjamin Lerner",
                     first_name: "Benjamin",
                     last_name: "Lerner",
                     nickname: "Ben",
                     site_admin: true,
                     )
end
