require 'test_helper'

class TermsControllerTest < ActionController::TestCase
  setup do
    @term = create(:term)
    @ken  = create(:admin_user)

    @bad  = create(:term)
  end

  test "should get index" do
    sign_in @ken
    get :index, {}
    assert_response :success
    assert_not_nil assigns(:terms)
  end

  test "should get new" do
    sign_in @ken
    get :new
    assert_response :success
  end

  test "should create term" do
    sign_in @ken
    assert_difference('Term.count') do
      post :create, {term: { name: @term.name }}
    end

    assert_redirected_to term_path(assigns(:term))
  end

  test "should show term" do
    sign_in @ken
    get :show, {id: @term}
    assert_response :success
  end

  test "should get edit" do
    sign_in @ken
    get :edit, {id: @term}
    assert_response :success
  end

  test "should update term" do
    sign_in @ken
    put :update, {id: @term, term: { name: @term.name }}
    assert_redirected_to term_path(assigns(:term))
  end

  test "should destroy term" do
    sign_in @ken
    assert_difference('Term.count', -1) do
      delete :destroy, {id: @bad}
    end

    assert_redirected_to terms_path
  end
end
