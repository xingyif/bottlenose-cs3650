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

    # subs = []
    # hws.each do |hw|
    #   regs.each do |reg|
    #     0.upto(4) do |ii|
    #       sub = Submission.find_or_create_by(
    #         student_notes: "sub #{ii}",
    #         assignment_id: hw.id,
    #         user_id: reg.user.id,
    #         auto_score: 50 + rand(50),
    #         teacher_score: 50 + rand(50),
    #       )
    #       sub.save!
    #       subs << sub
    #     end
    #   end
    # end

    # course_b = Course.first_or_create!(name: "Course B", term: fall)
    # course_c = Course.first_or_create!(name: "Course B", term: spring)
when "production"
   # I can't think of any seed data for productions.
end
