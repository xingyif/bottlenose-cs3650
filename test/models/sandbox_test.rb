require 'test_helper'
require 'fake_upload'

class SandboxTest < ActiveSupport::TestCase
  setup do
    make_standard_course
 end

  test "run a sandbox grader" do
    skip unless ENV['TEST_SANDBOX']

    assign = create(:assignment, type: "files", course: @cs101, name: "Test Assignment")
    grdtar = Rails.root.join('test', 'fixtures', 'files', 'TestScript', 'test.pl')
    upload = simulated_upload(@fred, grdtar)
    upload.save!
    grdcfg = build(:grader_config, type: "SandboxGrader", upload: upload, params: "lazy.rb")
    AssignmentGrader.create!(assignment: assign, grader_config: grdcfg)

    subprg = Rails.root.join('test', 'fixtures', 'files', 'TestScript', 'hello.c')
    sub = build(:submission, user: @john, assignment: assign, 
                upload_id: nil, ignore_late_penalty: true)
    sub.upload_file = FakeUpload.new(subprg)
    sub.save_upload
    sub.save!
    sub.autograde!

    assert_equal sub.score, 100
  end
end
