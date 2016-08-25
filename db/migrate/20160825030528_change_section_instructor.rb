class ChangeSectionInstructor < ActiveRecord::Migration
  def up
    remove_column :course_sections, :instructor
    add_column :course_sections, :instructor_id, :integer, null: false
  end
  def down
    remove_column :course_sections, :instructor_id
    add_column :course_sections, :instructor, :string, null: false
  end
end
