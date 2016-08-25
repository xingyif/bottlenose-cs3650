class CourseSection < ActiveRecord::Base
  belongs_to :course
  belongs_to :instructor, :class_name => "User", :foreign_key => "instructor_id", :primary_key => "id"

  validates :crn, presence: true
  validates :instructor, presence: true
  validates :meeting_time, length: { minimum: 3 }
  
  def to_s
    if self.meeting_time.to_s != ""
      "#{self.crn} : #{self.instructor.last_name} at #{self.meeting_time}"
    else
      "#{self.crn} : #{self.instructor.last_name}"
    end
  end
end
