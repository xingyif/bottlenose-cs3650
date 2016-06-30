require 'yaml'

class TapParser
  def initialize(text)
    @text = text
    @test_count = 0
    @tests = []
    @commentary = []
    lines = text.split("\n")
    parse_version(lines)
    parse_count(lines)
    parse_commentary(lines)
    parse_test(lines) while lines.count > 0
    @tests.length.upto(@test_count - 1) do |i|
      @tests[i] = missing_test(i + 1)
    end
  end

  def missing_test(i)
    {num: i, passed: false, missing: true}
  end

  def parse_version(lines)
    mm = lines[0].match(/^TAP version (\d+)$/)
    if mm
      @version = mm[1].to_i
      lines.shift
    end
  end

  def parse_count(lines)
    mm = lines[0].match(/^1\.\.(\d+)$/)
    if mm
      @test_count = mm[1].to_i
      lines.shift
    end
  end

  def parse_commentary(lines)
    while lines.length > 0 && lines[0].match(/^# /)
      @commentary.push(lines.shift[2..-1])
    end
  end

  def parse_test(lines)
    mm = lines[0].match(/^(not )?ok\b\s*(\d+)?([^#]*)(#.*)?$/)
    if mm
      lines.shift
      passed = mm[1].nil?
      num = mm[2]
      comment = mm[3]
      directives = []
      if mm[4]
        directives.push(mm[4][2..-1])
      end
      if num.nil?
        num = @tests.length
      else
        num = num.to_i - 1
        @tests.length.upto(num - 1) do |i|
          @tests.push(missing_test(i + 1))
        end
      end
      while lines.length > 0 && lines[0].match(/^# /)
        directives.push(lines.shift[2..-1])
      end
      test = {num: num + 1, passed: passed, missing: false, comment: comment, directives: directives}
      if lines.length > 0
        mm = lines[0].match(/^(\s+)---\s*$/)
        if mm
          test["info"] = parse_info(lines, mm[1])
        end
      end
      @tests.push test
    end
  end

  def parse_info(lines, indent)
    info = []
    regex = Regexp.new("^" + indent + "(.*)$")
    while lines.length > 0 && (mm = lines[0].match(regex))
      line = lines.shift
      break if line == (indent + "...")
      info.push(mm[1])
    end
    YAML.load(info.join("\n"))
  end

  def tests_ok
    tests = {}
    @text.split("\n").each do |line|
      # Passing test?
      mm = line.match(/^ok (\d+) -/)
      if mm
        nn = mm[1].to_i
        tests[nn] = 1 if tests[nn].nil?
      end

      # Failing test wins.
      mm = line.match(/^not ok (\d+) -/)
      if mm
        nn = mm[1].to_i
        tests[nn] = false
      end
    end

    # Count passing tests.
    points = 0
    1.upto(test_count) do |ii|
      points += 1 if tests[ii]
    end

    points
  end

  def points_available
    total_points = test_count

    @text.split("\n").each do |line|
      mm = line.match(/# TOTAL POINTS: (\d+)/)
      if mm
        total_points = mm[1].to_i
      end
    end

    total_points
  end

  def points_earned
    points = tests_ok

    @text.split("\n").each do |line|
      mm = line.match(/# POINTS: (\d+)/)
      if mm
        points = points + mm[1].to_i - 1
      end
    end

    points
  end

  def summary
    # <<-"SUMMARY"
    # Test count:        #{test_count}
    # Tests OK:          #{tests_ok}
    # Points available:  #{points_available}
    # Points earned:     #{points_earned}
    # SUMMARY
    
    nums = @tests.map {|t| t[:num] }

    <<-"SUMMARY"
    Version:    #{@version}
    Test count: #{@test_count}
    Test data: #{@tests}
    Test data: #{nums}
    Commentary: #{@commentary}
    Num tests: #{@tests.length}
    SUMMARY
  end
end
