require 'gradesheet'

class CourseSpreadsheet
  attr_reader :sheets

  class Col
    attr_reader :name
    attr_reader :type
    def initialize(name, type=nil)
      @name = name
      @type = type || "String"
    end
  end

  class Cell
    attr_reader :value
    attr_reader :formula
    def initialize(value=nil, formula=nil)
      debugger if value.nil? and formula.nil?
      @value = value
      @formula = formula
    end

    def as_cell(expectedType)
      if @formula
        ans = "<Cell".html_safe
        if expectedType == "Percent"
          ans << " ss:StyleID=\"TwoPct\"".html_safe
          expectedType = "Number"
        end
        ans << " ss:Formula=\"=".html_safe
        ans << @formula
        ans << "\"><Data ss:Type=\"".html_safe
        ans << expectedType
        ans << "\"></Data></Cell>".html_safe
        ans
      else
        if @value.is_a? Numeric
          type = "Number"
        elsif (@value == true) or (@value == false)
          type = "Boolean"
        else
          type = "String"
        end
        ans = "<Cell".html_safe
        if expectedType == "Percent"
          ans << " ss:StyleID=\"TwoPct\"".html_safe
        end
        ans << "><Data ss:Type=\"".html_safe
        ans << type
        ans << "\">".html_safe
        if type == "Boolean"
          ans << (if @value then "1" else "0" end)
        else
          ans << @value.to_s
        end
        ans << "</Data></Cell>".html_safe
        ans
      end
    end
  end

  class Sheet
    attr_reader :name
    attr_reader :header_rows
    attr_reader :rows
    attr_reader :columns
    def initialize(name, columns=nil, header_rows=nil, rows=nil)
      @name = name
      @columns = columns || []
      @header_rows = header_rows || []
      @rows = rows || []
    end
    def col_index(name)
      @columns.find_index{|c| c.name == name}
    end
    def col_delta(from, to)
      col_index(from) - col_index(to)
    end
    def row_index(col_name, value)
      ci = col_index(col_name)
      @rows.find_index{|r| r[ci] == value} + @header_rows.length
    end

    def push_row(i, values)
      push_into(@rows, i, values)
    end

    def push_header_row(i, values)
      push_into(@header_rows, i, values)
    end

    protected
    def to_cell(val)
      if val.instance_of?(Cell)
        val
      else
        Cell.new(val)
      end
    end

    def push_into(arr, i, vals)
      unless vals.instance_of?(Array)
        vals = [vals]
      end
      if i.nil?
        row = vals.map{|v| to_cell(v)}
        arr.push(row)
        row
      else
        vals.map{|v| arr[i].push(to_cell(v)) }
        arr[i]
      end
    end
end

  
  def initialize(course)
    @sheets = []

    exams = create_exams(course, Sheet.new("Exams"))
    hws, hw_cols = create_hws(course, Sheet.new("Homework"), exams)
    summary = create_summary(course, Sheet.new("Summary"), exams, hws, hw_cols)
    @sheets.push(summary, exams, hws)
  end

  def create_exams(course, sheet)
    labels, weight, users = create_name_columns(course, sheet)

    sheet
  end

  def col_name(index)
    # zero-based, so col_name(0) == "A", col_name(26) == "AA"
    alph = ("A".."Z").to_a
    s, q = "", index + 1
    (q, r = (q - 1).divmod(26)) && s.prepend(alph[r]) until q.zero?
    s
  end

  def create_name_columns(course, sheet)
    sheet.columns.push(
      Col.new("LastName"), Col.new("FirstName"), Col.new("Instructor"),
      Col.new("NUID", "String"), Col.new("Email"),
      Col.new("Section", "Number"), Col.new("Withdrawn?", "Boolean"),
      Col.new(""), Col.new("")
    )
    labels = sheet.push_header_row(nil, ["", "", "", "", "", "", "", "", ""])
    weight = sheet.push_header_row(nil, ["", "", "", "", "", "", "", "", ""])

    users = course.students.order(:last_name, :first_name).to_a
    
    users.each do |u|
      sheet.push_row(nil, [u.last_name || u.name, u.first_name || "", "", "", u.email, "", false, "", ""])
    end

    return labels, weight, users
  end
  
  def create_hws(course, sheet, exams)
    labels, weight, users = create_name_columns(course, sheet)

    hw_cols = []

    course.assignments.order(:due_date).each do |assn|
      used_subs = assn.all_used_subs.to_a
      grades = Gradesheet.new(assn, used_subs)
      subs_for_grading = SubsForGrading.where(assignment: assn).to_a
      
      sheet.columns.push(Col.new(assn.name, "Number"))
      grades.configs.each_with_index do |g, i|
        sheet.columns.push(Col.new("", "Number")) if i > 0
        labels.push(Cell.new(g.type))
        weight.push(Cell.new(g.avail_score))
      end
      sheet.columns.push(Col.new("", "Number"), Col.new("", "Number"), Col.new("", "Percent"))
      labels.push(Cell.new("Total"), Cell.new("Lateness"), Cell.new("%"))
      weight.push(Cell.new(nil, "SUM($#{col_name(weight.count - grades.configs.count)}$3:$#{col_name(weight.count - 1)}$3)"), Cell.new(""), Cell.new(""))
      hw_cols.push [assn, weight.count - 1]
      
      users.each_with_index do |u, i|
        sub_id = subs_for_grading.find{|sfg| sfg.user_id == u.id}
        sub = grades.grades[:grades].find{|grade_row| grade_row[:sub].id == sub_id.submission_id} unless sub_id.nil?
        if sub.nil?
          grades.configs.each do |g| sheet.push_row(i, "") end
          sheet.push_row(i, [0, "No submission", 0])
        else
          sub[:staff_scores][:scores].each do |ss|
            sheet.push_row(i, ss[0] || "<none>")
          end
          sheet.push_row(i, sub[:staff_scores][:raw_score])
          if sub[:sub].ignore_late_penalty
            sheet.push_row(i, "<ignore>")
          else
            sheet.push_row(i, assn.lateness_config.late_penalty(assn, sub[:sub]))
          end
          sheet.push_row(i, sub[:sub].score / 100.0)
        end
      end
    end

    return sheet, hw_cols
  end

  def create_summary(course, sheet, exams, hws, hw_cols)
    labels, weight, users = create_name_columns(course, sheet)

    start_col = sheet.columns.count - 1

    hw_cols.each do |assn, col|
      sheet.columns.push(Col.new(assn.name, "Percent"))
      labels.push(Cell.new(assn.points_available / 100.0))
      weight.push(Cell.new(""))

      users.each_with_index do |u, i|
        sheet.push_row(i, Cell.new(nil, "#{hws.name}!$#{col_name(col)}$#{i + 4}"))
      end
    end

    sheet.columns.push(Col.new("Total", "Percent"))
    labels.push(Cell.new(""))
    weight.push(Cell.new(""))

    end_col = sheet.columns.count - 1
    
    users.each_with_index do |u, i|
      sheet.push_row(i, Cell.new(nil, "SUMPRODUCT($#{col_name(start_col)}$2:$#{col_name(end_col)}$2,$#{col_name(start_col)}#{i + 4}:$#{col_name(end_col)}#{i + 4})"))
    end
    
    sheet
  end
end
