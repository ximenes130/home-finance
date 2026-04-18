require "test_helper"

class BudgetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @groceries_april = budgets(:groceries_april)
    @dining_april = budgets(:dining_april)
    @groceries = categories(:groceries)
    @utilities = categories(:utilities)
  end

  # index

  test "index defaults to current month" do
    get budgets_path
    assert_response :success
    assert_select "h1", "Budgets"
    assert_select "h2", Date.current.strftime("%B %Y")
  end

  test "index shows budgets for a specific month" do
    get budgets_path(year: 2026, month: 4)
    assert_response :success
    assert_select "h2", "April 2026"
  end

  test "index shows budget details with progress" do
    get budgets_path(year: 2026, month: 4)
    assert_response :success
    assert_select "[role='progressbar']", minimum: 1
  end

  test "index shows summary totals" do
    get budgets_path(year: 2026, month: 4)
    assert_response :success
    assert_select "p", text: /Total Budgeted/i
    assert_select "p", text: /Total Spent/i
    assert_select "p", text: /Total Remaining/i
  end

  test "index shows empty state for month with no budgets" do
    get budgets_path(year: 2020, month: 1)
    assert_response :success
    assert_select "h3", /No budgets for January 2020/
  end

  test "index orders budgets by percent_used descending" do
    get budgets_path(year: 2026, month: 4)
    assert_response :success
    # Both groceries and dining should appear
    assert_select ".text-sm.font-medium.text-slate-900", minimum: 2
  end

  test "index contains month navigation links" do
    get budgets_path(year: 2026, month: 4)
    assert_response :success
    assert_select "a[aria-label='Previous month']"
    assert_select "a[aria-label='Next month']"
  end

  # show

  test "show displays budget details" do
    get budget_path(@groceries_april)
    assert_response :success
    assert_select "h1", @groceries_april.category.name
  end

  test "show displays progress bar" do
    get budget_path(@groceries_april)
    assert_response :success
    assert_select "[role='progressbar']"
  end

  test "show lists transactions for the budget period" do
    get budget_path(@groceries_april)
    assert_response :success
    # grocery_april fixture is in April for groceries category
    assert_select ".text-sm.font-medium.text-slate-900", text: "Weekly groceries"
  end

  test "show displays back link to budgets index" do
    get budget_path(@groceries_april)
    assert_response :success
    assert_select "a", text: /Back to Budgets/
  end

  # new

  test "new renders the form" do
    get new_budget_path
    assert_response :success
    assert_select "form"
  end

  test "new pre-fills year and month from params" do
    get new_budget_path(year: 2026, month: 6)
    assert_response :success
    assert_select "select[name='budget[month]'] option[selected]", text: "June"
  end

  test "new only shows expense categories" do
    get new_budget_path
    assert_response :success
    # Should not contain income categories like "Salary"
    assert_select "select[name='budget[category_id]'] option", text: "Salary", count: 0
    # Should contain expense categories like "Groceries"
    assert_select "select[name='budget[category_id]'] option", text: "Groceries"
  end

  # create

  test "create with valid params creates budget and redirects" do
    assert_difference("Budget.count", 1) do
      post budgets_path, params: { budget: { category_id: @utilities.id, year: 2026, month: 6, amount_limit: 200.00 } }
    end
    assert_redirected_to budgets_path(year: 2026, month: 6)
    follow_redirect!
    assert_select "div", /Budget was successfully created/
  end

  test "create with invalid params renders new with errors" do
    assert_no_difference("Budget.count") do
      post budgets_path, params: { budget: { category_id: @groceries.id, year: 2026, month: 4, amount_limit: nil } }
    end
    assert_response :unprocessable_entity
    assert_select "form"
  end

  test "create with duplicate category/month is rejected" do
    assert_no_difference("Budget.count") do
      post budgets_path, params: { budget: { category_id: @groceries.id, year: 2026, month: 4, amount_limit: 300.00 } }
    end
    assert_response :unprocessable_entity
  end

  # edit

  test "edit renders the form" do
    get edit_budget_path(@groceries_april)
    assert_response :success
    assert_select "form"
  end

  test "edit shows category as read-only" do
    get edit_budget_path(@groceries_april)
    assert_response :success
    # Category name displayed as text, not as a select
    assert_select "select[name='budget[category_id]']", count: 0
    assert_select "p", text: @groceries_april.category.name
  end

  # update

  test "update with valid params updates budget and redirects" do
    patch budget_path(@groceries_april), params: { budget: { amount_limit: 500.00 } }
    assert_redirected_to budgets_path(year: 2026, month: 4)
    assert_equal 500.00, @groceries_april.reload.amount_limit
  end

  test "update with invalid params renders edit with errors" do
    patch budget_path(@groceries_april), params: { budget: { amount_limit: -10 } }
    assert_response :unprocessable_entity
    assert_select "form"
  end

  test "update does not allow changing category" do
    original_category_id = @groceries_april.category_id
    patch budget_path(@groceries_april), params: { budget: { category_id: @utilities.id, amount_limit: 500.00 } }
    assert_redirected_to budgets_path(year: 2026, month: 4)
    assert_equal original_category_id, @groceries_april.reload.category_id
  end

  # destroy

  test "destroy deletes budget and redirects" do
    assert_difference("Budget.count", -1) do
      delete budget_path(@groceries_april)
    end
    assert_redirected_to budgets_path(year: 2026, month: 4)
    follow_redirect!
    assert_select "div", /Budget was successfully deleted/
  end

  # navigation

  test "navigation links point to correct months" do
    get budgets_path(year: 2026, month: 1)
    assert_response :success
    # Previous month should be December 2025
    assert_select "a[href='#{budgets_path(year: 2025, month: 12)}']"
    # Next month should be February 2026
    assert_select "a[href='#{budgets_path(year: 2026, month: 2)}']"
  end

  test "navigation across year boundary works" do
    get budgets_path(year: 2026, month: 12)
    assert_response :success
    assert_select "a[href='#{budgets_path(year: 2026, month: 11)}']"
    assert_select "a[href='#{budgets_path(year: 2027, month: 1)}']"
  end

  test "budgets nav item is in sidebar" do
    get budgets_path
    assert_response :success
    assert_select "nav a", text: "Budgets"
  end
end
