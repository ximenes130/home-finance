require "test_helper"

class Accounts::ActivationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @checking = accounts(:checking)
    @inactive = accounts(:inactive)
  end

  test "create activates an inactive account" do
    post account_activation_path(@inactive)
    assert_redirected_to account_path(@inactive)
    assert @inactive.reload.active?
    follow_redirect!
    assert_select "div", /has been reactivated/
  end

  test "destroy deactivates an active account" do
    delete account_activation_path(@checking)
    assert_redirected_to account_path(@checking)
    assert_not @checking.reload.active?
    follow_redirect!
    assert_select "div", /has been deactivated/
  end
end
