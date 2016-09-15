class GraderConfig < ActiveRecord::Base
  belongs_to :submission
  belongs_to :grader_config
  belongs_to :upload

  def self.unique
    select(column_names - ["id"]).distinct
  end

  def grade(assignment, submission)
    ans = do_grading(assignment, submission)
    submission.compute_grade! if submission.grader_complete?
    ans
  end

  def autograde?
    false
  end

  def autograde!(assignment, submission)
    grade(assignment, submission)
  end
  
  def grader_exists_for(sub)
    !Grader.find_by(grader_config_id: self.id, submission_id: sub.id).nil?
  end


  def upload_file
    if @upload_data
      @upload_data.original_filename
    elsif self.upload
      self.upload.file_name
    else
      nil
    end
  end
  
  def upload_file=(data)
    if data.nil?
      errors[:base] << "You need to submit a file."
      return
    end
    self.upload_id_will_change! if self.upload.nil? or (self.upload.id != data.id)
    self.upload = data
  end
  
  protected

  def do_grading(assignment, submission)
    fail NotImplementedError, "Each grader should implement this"
  end
  
  def grader_for(sub)
    g = Grader.find_or_create_by(grader_config_id: self.id, submission_id: sub.id)
    if g.new_record?
      g.out_of = self.avail_score
    end
    g
  end
end
