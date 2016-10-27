require 'gradesheet'
require 'write_xlsx'
require 'stringio'


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
def col_name(index)
  # zero-based, so col_name(0) == "A", col_name(26) == "AA"
  alph = ("A".."Z").to_a
  s, q = "", index + 1
  (q, r = (q - 1).divmod(26)) && s.prepend(alph[r]) until q.zero?
  s
end



class CourseSpreadsheet
  attr_reader :sheets

  class Col
    attr_reader :name
    attr_reader :type
    attr_accessor :col
    def initialize(name, type=nil)
      @name = name
      @type = type || "String"
    end
  end

  class Formula
    attr_accessor :function
    attr_accessor :args
    def initialize(function, *args)
      @function = function
      @args = args
    end
    def to_s
      "#{@function}(#{@args.map(&:to_s).join(',')})"
    end
  end

  class CellRef
    attr_accessor :sheet_name
    attr_accessor :col
    attr_accessor :row
    def initialize(sheet_name, col, row)
      @sheet_name = sheet_name
      @col = col
      @row = row
    end
    def to_s
      "#{@sheet_name}!$#{@col}$#{@row}"
    end
  end

  class Range
    attr_accessor :from_col
    attr_accessor :from_row
    attr_accessor :to_col
    attr_accessor :to_row
    def initialize(from_col, from_row, to_col, to_row)
      @from_col = from_col
      @from_row = from_row
      @to_col = to_col
      @to_row = to_row
    end
    def to_s
      "$#{@from_col}$#{@from_row}:$#{@to_col}$#{@from_row}"
    end
    def contains(col, row)
      print "col: #{col}, row: #{row}, from_col/row: #{@from_col}/#{@from_row}, to_col/row: #{@to_col}/#{@to_row}\n"
      (@from_row <= row) and (row <= @to_row) and (@from_col <= col) and (col <= @to_col)
    end
  end
  
  class Cell
    attr_reader :value
    attr_reader :formula
    attr_accessor :sheet_name
    attr_accessor :row
    attr_accessor :col
    def initialize(value=nil, formula=nil)
      debugger if value.nil? and formula.nil?
      @value = value
      @formula = formula
    end

    def as_cell(expectedType)
      if @formula
        ans = "<!-- #{@col}#{@row} --><Cell".html_safe
        if expectedType == "Percent"
          ans << " ss:StyleID=\"TwoPct\"".html_safe
          expectedType = "Number"
        end
        ans << " ss:Formula=\"=".html_safe
        ans << @formula.to_s
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
        ans = "<!-- #{@col}#{@row} --><Cell".html_safe
        if expectedType == "Percent"
          ans << " ss:StyleID=\"TwoPct\"".html_safe
        end
        ans << "><Data ss:Type=\"".html_safe
        ans << type
        ans << "\">".html_safe
        if type == "Boolean"
          ans << (if @value then "1" else "0" end)
        elsif type == "DateTime"
          ans << @value.to_formatted_s(:db)
        else
          ans << @value.to_s
        end
        ans << "</Data></Cell>".html_safe
        ans
      end
    end

    def sanity_check
      return if @value
      return unless @row and @col
      if @formula.is_a? Formula
        @formula.args.each do |a|
          if a.is_a? Range and a.contains(@col, @row)
            raise RangeError, "Cell at #{@sheet_name}!#{@col}#{@row} contains formula #{@formula} that overlaps itself"
          end
        end
      elsif @formula.is_a? CellRef
        if @sheet_name == @formula.sheet_name and @row == @formula.row and @col == @formula.col
          raise RangeError, "CellRef at #{@formula} refers to itself"
        end
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

    def push_row(i, values)
      push_into(@rows, i, values)
    end

    def push_header_row(i, values)
      push_into(@header_rows, i, values)
    end

    def assign_coords
      @columns.each_with_index do |cell, c|
        cell.col = col_name(c)
      end
      @header_rows.each_with_index do |row, r|
        row.each_with_index do |cell, c|
          cell.sheet_name = @name
          cell.row = r + 1 + 1 # 1 for header row, and 1 for 1-based indexing
          cell.col = col_name(c)
        end
      end
      @rows.each_with_index do |row, r|
        row.each_with_index do |cell, c|
          cell.sheet_name = @name
          cell.row = r + @header_rows.length + 1 + 1 # 1 for header row, and 1 for 1-based indexing
          cell.col = col_name(c)
        end
      end
    end

    def sanity_check
      @header_rows.each do |r|
        r.each do |c| c.sanity_check end
      end
      @rows.each do |r|
        r.each do |c| c.sanity_check end
      end
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
    @sheets.each do |s|
      s.assign_coords
    end
  end

  def sanity_check
    @sheets.each do |s|
      s.sanity_check
    end
  end

  def create_exams(course, sheet)
    labels, weight, users = create_name_columns(course, sheet)

    sheet
  end

  def create_name_columns(course, sheet)
    sheet.columns.push(
      Col.new("LastName"), Col.new("FirstName"), Col.new("Instructor"),
      Col.new("NUID", "String"), Col.new("Email"),
      Col.new("Section", "Number"), Col.new("Withdrawn?", "DateTime"),
      Col.new(""), Col.new("")
    )
    labels = sheet.push_header_row(nil, ["", "", "", "", "", "", "", "", ""])
    weight = sheet.push_header_row(nil, ["", "", "", "", "", "", "", "", ""])

    users = course.students.order(:last_name, :first_name).to_a

    regs = course.registrations.includes(:section).to_a
    users.each do |u|
      reg = regs.find{|r| r.user_id == u.id}
      sheet.push_row(nil, [
                       u.last_name || u.name,
                       u.first_name || "",
                       reg.section.instructor.last_name,
                       u.nuid || "",
                       u.email,
                       reg.section.crn,
                       reg.dropped_date || "",
                       "", ""])
    end

    return labels, weight, users
  end
  
  def create_hws(course, sheet, exams)
    labels, weight, users = create_name_columns(course, sheet)

    hw_cols = []

    course.assignments.where.not(type: "exam").order(:due_date).each do |assn|
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
      weight.push(Cell.new(nil, Formula.new("SUM", Range.new(col_name(weight.count - grades.configs.count), 3, col_name(weight.count - 1), 3))), Cell.new(""), Cell.new(""))
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
          if sub[:sub].score
            sheet.push_row(i, sub[:sub].score / 100.0)
          else
            sheet.push_row(i, 0)
          end
        end
      end
    end

    return sheet, hw_cols
  end

  def create_summary(course, sheet, exams, hws, hw_cols)
    labels, weight, users = create_name_columns(course, sheet)

    hw_headers = hws.header_rows.count + 1 + 1 # 1 for the header labels, and one because 1-indexed

    start_col = sheet.columns.count

    hw_cols.each do |assn, col|
      sheet.columns.push(Col.new(assn.name, "Percent"))
      labels.push(Cell.new(assn.points_available / 100.0))
      weight.push(Cell.new(""))

      users.each_with_index do |u, i|
        sheet.push_row(i, Cell.new(nil, CellRef.new(hws.name, col_name(col), i + hw_headers)))
      end
    end

    end_col = sheet.columns.count - 1

    sheet.columns.push(Col.new("Total", "Percent"))
    labels.push(Cell.new(""))
    weight.push(Cell.new(""))
    
    users.each_with_index do |u, i|
      sheet.push_row(i, Cell.new(nil, Formula.new("SUMPRODUCT", Range.new(col_name(start_col), 2, col_name(end_col), 2), Range.new(col_name(start_col), i + hw_headers, col_name(end_col), i + hw_headers))))
    end
    
    sheet
  end

  def to_xlsx
    io = StringIO.new
    workbook = WriteXLSX.new(io)

    twoPct = workbook.add_format
    twoPct.set_num_format("0.00%")
    @sheets.each do |s|
      ws = workbook.add_worksheet(s.name)
      row_offset = 0
      s.columns.each_with_index do |c, c_num|
        ws.write(0 + row_offset, c_num, c.name)
      end
      row_offset += 1
      s.header_rows.each_with_index do |r, r_num|
        r.each_with_index do |c, c_num|
          if c.value
            to_write = c.value.to_s
          else
            to_write = "=#{c.formula}"
          end
          if s.columns[c_num].type == "Percent"
            ws.write(r_num + row_offset, c_num, to_write, twoPct)
          else
            ws.write(r_num + row_offset, c_num, to_write)
          end
        end
      end
      row_offset += s.header_rows.count
      s.rows.each_with_index do |r, r_num|
        r.each_with_index do |c, c_num|
          if c.value
            to_write = c.value.to_s
          else
            to_write = "=#{c.formula}"
          end
          if s.columns[c_num].type == "Percent"
            ws.write(r_num + row_offset, c_num, to_write, twoPct)
          else
            ws.write(r_num + row_offset, c_num, to_write)
          end
        end
      end
    end
    workbook.close
    io.string
  end
end
