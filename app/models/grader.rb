require 'tap_parser'

class Grader < ActiveRecord::Base
  belongs_to :submission
  belongs_to :grader_config

  def comments
    if self.grading_output.nil?
      {}
    else
      ans = {}
      begin
        tap = TapParser.new(File.read(self.grading_output))
      rescue Exception
        return ans
      end
      tap.tests.each do |t|
        by_file = ans[t[:info]["filename"]]
        by_file = ans[t[:info]["filename"]] = {} if by_file.nil?
        by_line = by_file[t[:info]["line"]]
        by_line = by_file[t[:info]["line"]] = [] if by_line.nil?
        by_line.push t
      end
      ans
    end
  end
end
