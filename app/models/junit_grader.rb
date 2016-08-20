require 'open3'
require 'tap_parser'
require 'audit'

class JunitGrader < GraderConfig
  def autograde?
    true
  end

  def to_s
    klass, filename = "Grade03Resubumit:hw_03.zip".split(":") #self.config
    "#{self.avail_score} points: Run JUnit tests in #{klass} from #{filename}"
  end
  
  protected
  def do_grading(assignment, sub)
    g = self.grader_for sub
    u = sub.upload
    files_dir = u.extracted_path
    grader_dir = u.grader_path(g)

    grader_dir.mkpath

    assets_dir = Rails.root.join('lib/assets')
    prefix = "Assignment #{assignment.id}, submission #{sub.id}"
    
    File.open(grader_dir.join("junit.tap"), "w") do |junit|
      File.open(grader_dir.join("details.log"), "w") do |details|
        Dir.mktmpdir("grade-#{sub.id}-#{g.id}") do |build_dir|
        # build_dir = grader_dir.join("build")
        # build_dir.mkpath
          Audit.log("#{prefix}: Grading in #{build_dir}")
          FileUtils.cp_r("#{files_dir}/.", build_dir)
          FileUtils.cp_r(Rails.root.join('lib/assets/junit-4.12.jar'), build_dir)
          FileUtils.cp_r(Rails.root.join('lib/assets/hamcrest-core-1.3.jar'), build_dir)
          FileUtils.cp(Rails.root.join("hw2/grading/Grade03resubmit.java"), build_dir)
          FileUtils.cp(Rails.root.join("hw2/grading/GradingSandbox.java"), build_dir)
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
                details.write("Errors building #{file}:\n")
                details.write(comp_err)
                Audit.log("#{prefix}: #{file} failed with compilation errors; see details.log")
                any_problems = true
              end
            end
            
            # details.write "Contents of temp directory are:\n"
            # output, status = Open3.capture2("ls", "-R", build_dir.to_s)
            # details.write output

            Audit.log("#{prefix}: Running JUnit")
            test_out, test_err, test_status = # FIXME
                                Open3.capture3("java", "-cp", ".:./*", "edu.neu.cs3500.TAPRunner", "Grade03resubmit")
            details.write("JUnit output: (exit status #{test_status})\n")
            details.write(test_out)
            if !test_status.success?
              details.write("JUnit errors:\n")
              details.write(test_err)
              Audit.log("#{prefix}: JUnit failed with errors; see details.log")
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
              junit.write(test_out)
              g.grading_output = junit.path

              tap = TapParser.new(test_out)
              g.score = tap.points_earned
              g.out_of = tap.points_available
              g.updated_at = DateTime.now
              g.available = true
              g.save!
              
              Audit.log("#{prefix}: JUnit gives raw score of #{g.score} / #{g.out_of}")
              return self.avail_score.to_f * (tap.points_earned.to_f / tap.points_available.to_f)
            end
          end
        end
      end
    end
    return 0
  end
end
