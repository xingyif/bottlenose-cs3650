require 'securerandom'
require 'tap_parser'
require 'audit'
require 'container'

class SandboxGrader < GraderConfig
  def autograde?
    true
  end

  def display_type
    "Sandboxed Script"
  end
  
  def to_s
    if self.upload
      "#{self.avail_score} points: Run sandboxed script, using #{self.upload.file_name}"
    else
      "#{self.avail_score} points: Run sandboxed script"
    end
  end

  protected
  
  def do_grading(assignment, sub)
    file = sub.upload.submission_path
    secret = SecureRandom.hex(16)

    puts "sandbox_grader::do_grading - #1"

    sandbox = Sandbox.create
    cont    = sandbox.container

    cont.start!
    cont.mkdir("/tmp/bn")
    cont.chmod("/tmp/bn", 0711)
    cont.mkdir("/tmp/bn/#{secret}")
    cont.push_dir(Rails.root.join('sandbox', 'lib'), "/tmp/bn")

    sandbox_sub_path = "/home/student/#{sub.upload.file_name}"
    cont.push(file, sandbox_sub_path)

    sandbox_gra_path = "/tmp/bn/#{self.upload.file_name}"
    cont.push(self.upload.submission_path, sandbox_gra_path)
    cont.push_dir(self.upload.extracted_path, "/tmp/bn/#{secret}")
    
    if File.exists?(self.upload.extracted_path.join('extracted', 'script'))
      cont.chmod("/tmp/bn/#{secret}/extracted/script", 0755)
    end
    
    puts "sandbox_grader::do_grading - #2"

    driver = Rails.root.join('sandbox', 'drivers', params)
    stdout, stderr, rv = cont.exec_driver(driver, secret, sandbox_sub_path, sandbox_gra_path)

    puts stdout

    parts = stdout.split("#{secret}\n")
    if parts.size < 3
      puts "Not enough parts"
      return 0.0
    end
      
    tap = TapParser.new(parts[1])
    Audit.log "Sandbox grader results: Tap: #{tap.points_earned}\n"
    
    g = self.grader_for sub
    g.score = tap.points_earned
    g.out_of = tap.points_available
    g.updated_at = DateTime.now
    g.available = true
    g.notes = "== stdout ==\n\n#{stdout}\n\n== stderr ==\n\n#{stderr}\n\n"
    g.save!

    puts g.notes

    sandbox.destroy!

    return self.avail_score.to_f * (tap.points_earned.to_f / tap.points_available.to_f)
  end
end
