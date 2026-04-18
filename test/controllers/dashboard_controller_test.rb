require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "show renders successfully" do
    get root_path
    assert_response :success
    assert_select "h1", "Dashboard"
  end

  test "show displays summary cards with current month data" do
    get root_path
    assert_response :success
    assert_select "p", text: /Net Balance/i
    assert_select "p", text: /Income This Month/i
    assert_select "p", text: /Expenses This Month/i
    assert_select "p", text: /Net This Month/i
  end

  test "show displays current month label" do
    get root_path
    assert_response :success
    assert_select "span", text: Date.current.strftime("%B %Y")
  end

  test "show displays accounts overview" do
    get root_path
    assert_response :success
    assert_select "h2", text: /Accounts/i
    assert_select "a", text: accounts(:checking).name
    assert_select "a", text: accounts(:savings).name
  end

  test "show displays recent transactions" do
    get root_path
    assert_response :success
    assert_select "h2", text: /Recent Transactions/i
  end

  test "show displays quick action links" do
    get root_path
    assert_response :success
    assert_select "a", text: /Add Transaction/
    assert_select "a", text: /New Transfer/
    assert_select "a", text: /View All Transactions/
  end

  test "show displays budget status section" do
    get root_path
    assert_response :success
    assert_select "h2", text: /Budget Status/i
  end

  test "show displays budget at risk when percent used >= 80" do
    budget = budgets(:dining_april)
    # dining_april: limit $50, spent $45 = 90%
    get root_path
    assert_response :success
    assert_select "span", text: budget.category.name
  end

  test "show renders empty state when no accounts exist" do
    Transaction.delete_all
    CsvImport.delete_all
    Account.delete_all

    get root_path
    assert_response :success
    assert_select "h2", text: /Welcome to Home Finance/
    assert_select "a", text: /Create Your First Account/
  end

  test "show does not display inactive accounts in overview" do
    get root_path
    assert_response :success
    assert_select "a", text: accounts(:inactive).name, count: 0
  end
end
