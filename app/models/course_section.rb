class CourseSection < ActiveRecord::Base
  belongs_to :course

  def to_s
    if self.meeting_time.to_s != ""
      "#{self.crn} : #{self.instructor} at #{self.meeting_time}"
    else
      "#{self.crn} : #{self.instructor}"
    end
  end
end
