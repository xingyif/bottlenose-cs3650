class InlineComment < ActiveRecord::Base
  belongs_to :submission
  belongs_to :user
  belongs_to :grader
  enum severity: [:error, :warning, :info]

  def upload_filename
    Upload.upload_path_for(self.filename)
  end

  def to_json
    {
      id: self.id,
      file: self.upload_filename,
      line: self.line,
      author:
        if self.user
          self.user.name
        else
          ""
        end,
      grader: self.grader_id,
      title: self.title,
      label: self.label,
      severity: self.severity.humanize,
      comment: self.comment,
      deduction: self.weight,
      suppressed: self.suppressed,
      info: self.info
    }
  end
  def to_editable_json(comment_author)
    ans = to_json
    ans[:editable] = (self.user and comment_author and comment_author.id == self.user.id)
    ans
  end
end
