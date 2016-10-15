require 'open3'
require 'tap_parser'
require 'audit'

class CheckerGrader < GraderConfig
  validates :upload, presence: true
  validates :params, length: {minimum: 3}
  
  def autograde?
    true
  end

  def display_type
    "Checker tests"
  end
  
  def to_s
    if self.upload
      filename = self.upload.file_name
    else
      filename = "<no file>"
    end
    "#{self.avail_score} points: Run Checker tests in #{self.params} from #{filename}"
  end

  def grade(assignment, sub)
    g = self.grader_for sub
    u = sub.upload
    files_dir = u.extracted_path
    grader_dir = u.grader_path(g)

    grader_dir.mkpath

    assets_dir = Rails.root.join('lib/assets')
    prefix = "Assignment #{assignment.id}, submission #{sub.id}"
    
    File.open(grader_dir.join("checker.tap"), "w") do |checker|
      File.open(grader_dir.join("details.log"), "w") do |details|
        Dir.mktmpdir("grade-#{sub.id}-#{g.id}") do |build_dir|
        # build_dir = grader_dir.join("build")
        # build_dir.mkpath
          Audit.log("#{prefix}: Grading in #{build_dir}")
          FileUtils.cp_r("#{files_dir}/.", build_dir)
          FileUtils.cp("#{assets_dir}/tester-2.jar", build_dir)
          FileUtils.cp_r("#{self.upload.extracted_path}/.", build_dir)
          # details.write "Contents of temp directory are:\n"
          # output, status = Open3.capture2("ls", "-R", build_dir.to_s)
          # details.write output
          
          FileUtils.cd(build_dir) do
            any_problems = false
            Dir.glob("**/*.java").each do |file|
              Audit.log "#{prefix}: Compiling #{file}"
              comp_out, comp_err, comp_status = Open3.capture3("javac", "-cp", ".:./*", file)
              details.write("Compiling #{file}: (exit status #{comp_status})\n")
              details.write(comp_out)
              if !comp_status.success?
                details.write("Errors building student code:\n")
                details.write(comp_err)
                Audit.log("#{prefix}: #{file} failed with compilation errors; see details.log")
                any_problems = true
              end
            end
            
            # details.write "Contents of temp directory are:\n"
            # output, status = Open3.capture2("ls", "-R", build_dir.to_s)
            # details.write output

            Audit.log("#{prefix}: Running Checker")
            test_out, test_err, test_status =
                                Open3.capture3("java", "-cp", ".:./*", "tester.Main", "-tap", self.params)
            details.write("Checker output: (exit status #{test_status})\n")
            details.write(test_out)
            if !test_status.success?
              details.write("Checker errors:\n")
              details.write(test_err)
              Audit.log("#{prefix}: Checker failed with errors; see details.log")
              any_problems = true
            end

            if any_problems
              g.grading_output = details.path
              g.score = 0
              g.out_of = self.avail_score

              g.updated_at = DateTime.now
              g.available = true
              g.save!

              Audit.log("#{prefix}: Errors prevented grading; giving a 0")
              return 0
            else
              begin
                checker.write(test_out)
                g.grading_output = checker.path
                
                tap = TapParser.new(test_out)
                g.score = tap.points_earned
                g.out_of = tap.points_available
                g.updated_at = DateTime.now
                g.available = true
                g.save!
                
                Audit.log("#{prefix}: Checker gives raw score of #{g.score} / #{g.out_of}")
                return self.avail_score.to_f * (tap.points_earned.to_f / tap.points_available.to_f)
              rescue Exception
                g.grading_output = details.path
                g.score = 0
                g.out_of = self.avail_score
                g.updated_at = DateTime.now
                g.available = true
                g.save!
                Audit.log("#{prefix}: Errors prevented grading; giving a 0")
                return 0
              end
            end
          end
        end
      end
    end
    return 0
  end
end
