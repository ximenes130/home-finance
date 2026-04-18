require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @checking = accounts(:checking)
    @inactive = accounts(:inactive)
  end

  # index

  test "index lists all accounts" do
    get accounts_path
    assert_response :success
    assert_select "h1", "Accounts"
  end

  test "index shows active accounts before inactive" do
    get accounts_path
    assert_response :success
    assert_select "table tbody tr"
  end

  # show

  test "show displays account details" do
    get account_path(@checking)
    assert_response :success
    assert_select "h1", @checking.name
  end

  test "show displays recent transactions" do
    get account_path(@checking)
    assert_response :success
  end

  test "show displays delete button for deletable account" do
    get account_path(@inactive)
    assert_response :success
    assert_select "button", text: "Delete"
  end

  test "show hides delete button for non-deletable account" do
    get account_path(@checking)
    assert_response :success
    assert_select "button", text: "Delete", count: 0
  end

  # new

  test "new renders the form" do
    get new_account_path
    assert_response :success
    assert_select "form"
  end

  # create

  test "create with valid params creates account and redirects" do
    assert_difference("Account.count", 1) do
      post accounts_path, params: { account: { name: "New Savings", account_type: "savings", opening_balance: 500 } }
    end
    assert_redirected_to accounts_path
    follow_redirect!
    assert_select "div", /Account was successfully created/
  end

  test "create with invalid params renders new with errors" do
    assert_no_difference("Account.count") do
      post accounts_path, params: { account: { name: "", account_type: "checking" } }
    end
    assert_response :unprocessable_entity
    assert_select "form"
  end

  test "create with duplicate name renders new with errors" do
    assert_no_difference("Account.count") do
      post accounts_path, params: { account: { name: @checking.name, account_type: "savings" } }
    end
    assert_response :unprocessable_entity
  end

  # edit

  test "edit renders the form" do
    get edit_account_path(@checking)
    assert_response :success
    assert_select "form"
  end

  # update

  test "update with valid params updates account and redirects" do
    patch account_path(@checking), params: { account: { name: "Updated Name" } }
    assert_redirected_to account_path(@checking)
    assert_equal "Updated Name", @checking.reload.name
  end

  test "update with invalid params renders edit with errors" do
    patch account_path(@checking), params: { account: { name: "" } }
    assert_response :unprocessable_entity
    assert_select "form"
  end

  # destroy

  test "destroy deletable account removes it and redirects" do
    assert_difference("Account.count", -1) do
      delete account_path(@inactive)
    end
    assert_redirected_to accounts_path
  end

  test "destroy non-deletable account redirects with alert" do
    assert_no_difference("Account.count") do
      delete account_path(@checking)
    end
    assert_redirected_to account_path(@checking)
    follow_redirect!
    assert_select "div", /Cannot delete account with transactions/
  end
end
