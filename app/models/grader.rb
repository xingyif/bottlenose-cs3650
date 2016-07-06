class Grader < ActiveRecord::Base
  belongs_to :submission
  belongs_to :grader_config
end
