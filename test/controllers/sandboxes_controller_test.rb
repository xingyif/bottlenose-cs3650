require 'test_helper'

class SandboxesControllerTest < ActionController::TestCase
  setup do
    @sandbox = sandboxes(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:sandboxes)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create sandbox" do
    assert_difference('Sandbox.count') do
      post :create, sandbox: { name: @sandbox.name, submission_id: @sandbox.submission_id }
    end

    assert_redirected_to sandbox_path(assigns(:sandbox))
  end

  test "should show sandbox" do
    get :show, id: @sandbox
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @sandbox
    assert_response :success
  end

  test "should update sandbox" do
    patch :update, id: @sandbox, sandbox: { name: @sandbox.name, submission_id: @sandbox.submission_id }
    assert_redirected_to sandbox_path(assigns(:sandbox))
  end

  test "should destroy sandbox" do
    assert_difference('Sandbox.count', -1) do
      delete :destroy, id: @sandbox
    end

    assert_redirected_to sandboxes_path
  end
end
