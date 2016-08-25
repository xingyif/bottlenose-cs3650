class Questionaire < ActiveRecord::Base
  belongs_to :blame, :class_name => "User", :foreign_key => "blame_id"
  belongs_to :assignment
  belongs_to :course
  belongs_to :lateness_config

  validates :name,      :uniqueness => { :scope => :course_id }
  validates :name,      :presence => true
  validates :course_id, :presence => true
  validates :due_date,  :presence => true
  validates :blame_id,  :presence => true
  validates :points_available, :numericality => true
  validates :lateness_config, :presence => true
  validate :valid_lateness_config

  has_many :questions, :dependent => :destroy

  accepts_nested_attributes_for :questions
  
  def valid_lateness_config
    if !self.lateness_config.valid?
      self.lateness_config.errors.full_messages.each do |m|
        @errors[:base] << m
      end
    end
  end

end
