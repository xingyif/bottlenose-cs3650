[Course, Bucket, Assignment, Registration].each do |model|
    model.reset_column_information
end

case Rails.env
when "development"
    # Create four users.
    ben = User.create!(
        email: "blerner@ccs.neu.edu",
        name: "Ben Lerner",
    )
    olin = User.create!(
        email: "shivers@ccs.neu.edu",
        name: "Olin Shivers",
    )
    amal = User.create!(
        email: "amal@ccs.neu.edu",
        name: "Amal Ahmed",
    )
    nate = User.create!(
        email: "lilienthal.n@husky.neu.edu",
        name: "Nathan Lilienthal",
    )

    # Create two terms.
    fall = Term.create!(name: "Fall 2016")
    spring = Term.create!(name: "Spring 2016")

    # The first course.
    fundies1 = Course.create!(
        name: "Fundamentals of Computer Science 1",
        term: fall,
    )
    0.upto(5).each do |i|
        assignment = Assignment.create!(
            name: "Homework #{i}",
            assignment: "This is an example homework assignment, don't try to actually do this.",
            course: fundies1,
            bucket: fundies1.buckets.first,
            blame: ben,
            due_date: Time.now + (i * 1.week),
        )
    end
    [ben, olin, amal].each do |professor|
        Registration.create!(
            user: professor,
            course: fundies1,
            role: :professor,
            show_in_lists: false,
        )
    end
    [nate].each do |staff|
        Registration.create!(
            user: staff,
            course: fundies1,
            role: :assistant,
            show_in_lists: false,
        )
    end
    1.upto(300).each do |i|
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
    end

    fundies1.assignments.each do |assignment|
        fundies1.students.each do |student|
            upload = Upload.new
            upload.user_id = student.id
            upload.store_meta!({
                type:       "Submission File",
                user:       "#{student.name} (#{student.id})",
                course:     "#{assignment.course.name} (#{assignment.course.id})",
                date:       Time.now.strftime("%Y/%b/%d %H:%M:%S %Z")
            })
            submission_path = "#{Rails.root}/hw1/strings.rkt"
            submission_file = File.new(submission_path)
            upload.store_upload!(ActionDispatch::Http::UploadedFile.new(
                filename: File.basename(submission_file),
                tempfile: submission_file,
            ))
            upload.save!

            Submission.create!(
                upload_id: upload.id,
                student_notes: "A submission",
                assignment_id: assignment.id,
                user_id: student.id,
                auto_score: 50 + rand(50),
                teacher_score: 50 + rand(50),
            )
        end
    end
when "production"
   # I can't think of any seed data for productions.
end
