require 'open3'
require 'tap_parser'

class JavaStyleGrader < GraderConfig
  def grade(assignment, sub)
    g = self.grader_for sub
    u = sub.upload
    files_dir = u.extracted_path
    grader_dir = u.grader_path(g)

    grader_dir.mkpath

    print("Command line: java -jar #{Rails.root.join('lib/assets/StyleChecker.jar').to_s} #{files_dir.to_s} -maxPoints #{self.avail_score.to_s}\n")
    output, err, status = Open3.capture3("java", "-jar", Rails.root.join("lib/assets/StyleChecker.jar").to_s,
                 files_dir.to_s, "-maxPoints", self.avail_score.to_s)
    File.open(grader_dir.join("style.tap"), "w") do |style|
      style.write(output)
      g.grading_output = style.path
    end
    tap = TapParser.new(output)
    print "Tap: #{tap.points_earned}\n"

    g.score = tap.points_earned
    g.out_of = tap.points_available
    g.updated_at = DateTime.now
    g.available = true
    g.save!
    return self.avail_score * (tap.points_earned.to_f / tap.points_available.to_f)
  end
end
