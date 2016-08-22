require 'open3'
require 'tap_parser'

class JavaStyleGrader < GraderConfig
  def autograde?
    true
  end

  def to_s
    if self.upload
      "#{self.avail_score} points: Run Java style checker, using #{self.upload.file_name}"
    else
      "#{self.avail_score} points: Run Java style checker"
    end
  end

  protected
  
  def do_grading(assignment, sub)
    g = self.grader_for sub
    u = sub.upload
    files_dir = u.extracted_path
    grader_dir = u.grader_path(g)

    grader_dir.mkpath

    print("Command line: java -jar #{Rails.root.join('lib/assets/StyleChecker.jar').to_s} #{files_dir.to_s} -maxPoints #{self.avail_score.to_s}\n")
    output, err, status = Open3.capture3("java", "-jar", Rails.root.join("lib/assets/StyleChecker.jar").to_s,
                 files_dir.to_s, "-maxPoints", self.avail_score.to_s)
    File.open(grader_dir.join("style.tap"), "w") do |style|
      style.write(Upload.upload_path_for(output))
      g.grading_output = style.path
    end
    tap = TapParser.new(output)
    print "Tap: #{tap.points_earned}\n"

    g.score = tap.points_earned
    g.out_of = tap.points_available
    g.updated_at = DateTime.now
    g.available = true
    g.save!

    upload_inline_comments(tap, sub)
    
    return self.avail_score.to_f * (tap.points_earned.to_f / tap.points_available.to_f)
  end
  
  def upload_inline_comments(tap, sub)
    InlineComment.where(submission: sub, grader_config: self).destroy_all
    ics = tap.tests.map do |t|
      InlineComment.new(
        submission: sub,
        title: t[:comment],
        filename: t[:info]["filename"],
        line: t[:info]["line"],
        grader_config: self,
        user: nil,
        label: t[:info]["category"],
        severity: InlineComment::severities[t[:info]["severity"].humanize(:capitalize => false)],
        comment: t[:info]["message"],
        weight: t[:info]["weight"],
        suppressed: t[:info]["suppressed"])
    end
    InlineComment.import ics
  end

end
