class Gradesheet
  attr_reader :assignment
  attr_reader :submissions
  attr_reader :configs
  attr_reader :graders
  attr_reader :max_score
  attr_reader :grades
  def initialize(assignment, submissions)
    @assignment = assignment
    @submissions = submissions
    @configs = @assignment.assignment_graders.order(:order).includes(:grader_config).map{ |c| c.grader_config }
    @max_score = @configs.sum(&:avail_score)
    @graders = Grader.where(submission_id: @submissions.map(&:id)).group_by(&:submission_id)

    @raw_score = 0
    @grades = {names: @configs.map(&:type), grades: []}
    @submissions.each do |s|
      s_scores = {raw_score: 0.0, scores: []}
      b_scores = {raw_score: 0.0, scores: []}
      res = {sub: s, staff_scores: s_scores, blind_scores: b_scores}
      @configs.each do |c|
        g = @graders[s.id].find do |g| g.grader_config_id == c.id end
        if g
          if g.available?
            s_scores[:raw_score] += g.score
            s_scores[:scores].push [g.score, c.avail_score]

            b_scores[:scores].push [g.score, c.avail_score]
            if b_scores[:raw_score] 
              b_scores[:raw_score] += g.score
            end
          else
            s_scores[:raw_score] += g.score
            s_scores[:scores].push "(hidden #{g.score})"
            b_scores[:raw_score] = nil
            b_scores[:scores].push "not ready"
          end
        end        
      end
      @grades[:grades].push res
    end
  end
end
