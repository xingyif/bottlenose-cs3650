require 'devise/encryptor'

[Course, Bucket, Assignment, Registration].each do |model|
  model.reset_column_information
end

case Rails.env
when "development"
  # Create four users.
  ben = User.create!(
                     email: "blerner@ccs.neu.edu",
                     name: "Benjamin Lerner",
                     first_name: "Benjamin",
                     last_name: "Lerner",
                     nickname: "Ben",
                     site_admin: true,
                     )
  justin = User.create!(
                        email: "justin.case@fallback.ccs.neu",
                        name: "Justin Case",
                        first_name: "Justin",
                        last_name: "Case",
                        nickname: "Safetynet",
                        )
  justin.encrypted_password = Devise::Encryptor.digest(justin.class, "planet of the O0d")
  justin.save!

  olin = User.create!(
                      email: "shivers@ccs.neu.edu",
                      name: "Olin Shivers",
                      first_name: "Olin",
                      last_name: "Shivers"
                      )
  amal = User.create!(
                      email: "amal@ccs.neu.edu",
                      name: "Amal Ahmed",
                      first_name: "Amal",
                      last_name: "Ahmed"
                      )

  fixed_lateness = FixedDaysConfig.create!(days_per_assignment: 2)
  pct_lateness = LatePerDayConfig.create!(percent_off: 25, frequency: 1, days_per_assignment: 4)
  
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
  manual = ManualGrader.create!(avail_score: 42)
  junit = JunitGrader.create!(avail_score: 58, params: "Whee")
  style = JavaStyleGrader.create!(avail_score: 55)

  0.upto(5).each do |i|
    assignment = Assignment.create!(
                                    name: "Homework #{i}",
                                    assignment: "This is an example homework assignment, don't try to actually do this.",
                                    course: fundies1,
                                    bucket: fundies1.buckets.first,
                                    team_subs: i < 3,
                                    lateness_config: (i % 2 == 1) ? pct_lateness : nil,
                                    blame: ben,
                                    due_date: Time.now + ((i - 3) * 1.week),
                                    )
    if assignment.id > 3
      AssignmentGrader.create!(assignment_id: assignment.id, grader_config_id: junit.id, order: 1)
    end
    AssignmentGrader.create!(assignment_id: assignment.id, grader_config_id: style.id, order: 2)
    AssignmentGrader.create!(assignment_id: assignment.id, grader_config_id: manual.id, order: 3)
  end
  [ben, olin, amal].each do |professor|
    Registration.create!(
                         user: professor,
                         course: fundies1,
                         role: :professor,
                         show_in_lists: false,
                         )
  end
  students = 1.upto(300).map do |i|
    user = User.create!(
                        email: "user#{i}@example.com",
                        name: "User #{i}",
                        )
    Registration.create!(
                         user: user,
                         course: fundies1,
                         role: :student,
                         show_in_lists: true,
                         )
    user
  end

  1.upto(150).each do |i|
    Team.create!(
                 course_id: fundies1.id,
                 start_date: Date.current,
                 created_at: DateTime.current,
                 updated_at: DateTime.current,
                 users: [students[i - 1], students[i + 150 - 1]]
                 )
  end

  fundies1.assignments.each do |assignment|
    if assignment.team_subs?
      print "Creating team submissions for #{fundies1.students.count} students in #{assignment.name}\n"
      fundies1.students.each do |student|
        upload = Upload.new
        submit_time = assignment.due_date + 48.hours - rand(96).hours
        upload.user_id = student.id
        upload.store_meta!({
                             type:       "Team Submission File",
                             user:       "#{student.name} (#{student.id})",
                             course:     "#{assignment.course.name} (#{assignment.course.id})",
                             date:       submit_time.strftime("%Y/%b/%d %H:%M:%S %Z")
                           })
        submission_path = "#{Rails.root}/hw1/strings.rkt"
        submission_file = File.new(submission_path)
        upload.store_upload!(ActionDispatch::Http::UploadedFile.new(
                                                                    filename: File.basename(submission_file),
                                                                    tempfile: submission_file,
                                                                    ))
        upload.save!
        
        team = student.active_team_for(fundies1)
        sub = Submission.create!(
                                 upload_id: upload.id,
                                 student_notes: "A team effort",
                                 assignment_id: assignment.id,
                                 user: student,
                                 team: team
                                 created_at: submit_time,
                                 )
        sub.grade!
        sub.set_used_sub!
      end
    else
      print "Creating individual submissions for #{fundies1.students.count} students in #{assignment.name}\n"
      fundies1.students.each do |student|
        upload = Upload.new
        submit_time = assignment.due_date + 48.hours - rand(96).hours
        upload.user_id = student.id
        upload.store_meta!({
                             type:       "Submission File",
                             user:       "#{student.name} (#{student.id})",
                             course:     "#{assignment.course.name} (#{assignment.course.id})",
                             date:       submit_time.strftime("%Y/%b/%d %H:%M:%S %Z")
                           })
        submission_path = "#{Rails.root}/hw1/strings.rkt"
        submission_file = File.new(submission_path)
        upload.store_upload!(ActionDispatch::Http::UploadedFile.new(
                                                                    filename: File.basename(submission_file),
                                                                    tempfile: submission_file,
                                                                    ))
        upload.save!

        sub = Submission.create!(
                                 upload_id: upload.id,
                                 student_notes: "A submission",
                                 assignment_id: assignment.id,
                                 user: student,
                                 created_at: submit_time
                                 )
        sub.grade!
        sub.set_used_sub!
      end
    end
  end
when "production"
  # I can't think of any seed data for productions.
end
