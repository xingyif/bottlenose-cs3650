require 'open3'
require 'tap_parser'

class JunitGrader < GraderConfig
  def grade(assignment, sub)
    g = self.grader_for sub
    u = sub.upload
    files_dir = u.extracted_path
    grader_dir = u.grader_path(g)

    grader_dir.mkpath

    assets_dir = Rails.root.join('lib/assets')

    File.open(grader_dir.join("junit.tap"), "w") do |junit|
      File.open(grader_dir.join("details.log"), "w") do |details|
#        Dir.mktmpdir("grade-#{sub.id}-#{g.id}") do |build_dir|
        build_dir = grader_dir.join("build")
        build_dir.mkpath
          print "Made temp directory #{build_dir}\n"
          FileUtils.cp_r("#{files_dir}/.", build_dir)
          FileUtils.cp_r(Rails.root.join('lib/assets/.'), build_dir)
          FileUtils.cp(Rails.root.join("hw2/grading/Grade03resubmit.java"), build_dir)
          FileUtils.cp(Rails.root.join("hw2/grading/GradingSandbox.java"), build_dir)
          # print "Contents of temp directory are:\n"
          # output, status = Open3.capture2("ls", "-R", build_dir.to_s)
          # print output
          
          FileUtils.cd(build_dir) do
            print "Compiling student code\n"
            Dir.glob("**/*.java").each do |file|
              print "Compiling #{file}\n"
              comp_out, comp_err, comp_status = Open3.capture3("javac", "-cp", ".:./*", file)
              details.write("Building student code: (exit status #{comp_status})\n")
              details.write(comp_out)
              details.write("Errors building student code:\n")
              details.write(comp_err)
            end
            print "Done compiling\n"
            
            # print "Contents of temp directory are:\n"
            # output, status = Open3.capture2("ls", "-R", build_dir.to_s)
            # print output

            print "Running JUnit tests\n"
            test_out, test_err, test_status = # FIXME
                                Open3.capture3("java", "-cp", ".:./*", "edu.neu.cs3500.TAPRunner", "Grade03resubmit")
            details.write("JUnit output: (exit status #{test_status})\n")
            details.write(test_out)
            details.write("JUnit errors:\n")
            details.write(test_err)
            print "Done running, status is #{test_status} (#{test_err})\n"

            junit.write(test_out)
            g.grading_output = junit.path

            tap = TapParser.new(test_out)
            g.score = tap.points_earned
            g.out_of = tap.points_available
            g.updated_at = DateTime.now
            g.available = true
            g.save!

            return self.avail_score.to_f * (tap.points_earned.to_f / tap.points_available.to_f)
          end
#        end
      end
    end
    return 0
  end
end
