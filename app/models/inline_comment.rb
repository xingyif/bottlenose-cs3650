class InlineComment < ActiveRecord::Base
  belongs_to :submission
  belongs_to :user
  belongs_to :grader_config
  enum severity: [:error, :warning, :info]

  def upload_filename
    Upload.upload_path_for(self.filename)
  end

  def to_json
    {
      filename: self.upload_filename,
      line: self.line,
      author:
        if self.user
          self.user.name
        else
          ""
        end,
      title: self.title,
      label: self.label,
      severity: self.severity.humanize,
      comment: self.comment,
      weight: self.weight,
      suppressed: self.suppressed,
      info: self.info
    }
  end
end
