class GraderConfig < ActiveRecord::Base
  belongs_to :submission
  belongs_to :grader_config
  belongs_to :upload

  def self.unique
    select(column_names - ["id"]).distinct
  end

  def grade(assignment, submission)
    ans = do_grading(assignment, submission)
    submission.compute_grade! if submission.graders.pluck(:available).all?
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
    return if data.nil?
    @upload_data = data
  end

  def save_upload(user)
    if @upload_data.nil?
      errors[:base] << "You need to submit a file."
      return
    end

    data = @upload_data

    up = Upload.new
    up.user_id = user.id
    up.store_upload!(data, {
      type:       "#{@type} Configuration",
      date:       Time.now.strftime("%Y/%b/%d %H:%M:%S %Z")
    })
    if up.save
      self.upload_id = up.id
      
      Audit.log("Sub #{id}: New configuration " +
                "(#{user.id}) with key #{up.secret_key}")
    else
      false
    end
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
