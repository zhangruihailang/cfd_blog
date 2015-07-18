require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end
  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:zhangrui)
  end
  
  test "password resets" do
    get new_password_reset_path
    assert_template 'password_resets/new'
    # email无效
    post password_resets_path, password_reset: { email: "" }
    assert_not flash.empty?
    assert_template 'password_resets/new'
    # emai有效
    post password_resets_path, password_reset: { email: @user.email }
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_not flash.empty?
    assert_redirected_to root_url
    # 密码重设表单
    user = assigns(:user)
    # email错误
    get edit_password_reset_path(user.reset_token, email: "")
    assert_redirected_to root_url
    # 用户未激活
    user.toggle!(:activated)
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_redirected_to root_url
    user.toggle!(:activated)
    # email正确，令牌错误
    get edit_password_reset_path('wrong token', email: user.email)
    assert_redirected_to root_url
    # email和令牌都正确
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_template 'password_resets/edit'
    assert_select "input[name=email][type=hidden][value=?]", user.email
    # 密码和密码确认不匹配
    patch password_reset_path(user.reset_token),
    email: user.email,
    user: { password: "foobaz",
    password_confirmation: "barquux" }
    assert_select 'div#error_explanation'
    # 密码和密码确认都为空
    patch password_reset_path(user.reset_token),
    email: user.email,
    user: { password: " ",
    password_confirmation: " " }
    assert_not flash.empty?
    assert_template 'password_resets/edit'
    # 密码和密码确认有效
    patch password_reset_path(user.reset_token),
    email: user.email,
    user: { password: "090125",
    password_confirmation: "090125" }
    assert is_logged_in?
    assert_not flash.empty?
    assert_redirected_to user
  end
end
