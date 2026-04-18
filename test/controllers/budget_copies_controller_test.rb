require "test_helper"

class BudgetCopiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @groceries_january = budgets(:groceries_january)
    @utilities_january = budgets(:utilities_january)
  end

  # new

  test "new renders the form" do
    get new_budget_copy_path(target_year: 2026, target_month: 4)
    assert_response :success
    assert_select "form"
  end

  test "new pre-fills target month label in description" do
    get new_budget_copy_path(target_year: 2026, target_month: 4)
    assert_response :success
    assert_select "strong", text: "April 2026"
  end

  test "new defaults source to previous month" do
    get new_budget_copy_path(target_year: 2026, target_month: 4)
    assert_response :success
    assert_select "select[name='budget_copy[source_month]'] option[selected]", text: "March"
  end

  test "new defaults source across year boundary" do
    get new_budget_copy_path(target_year: 2026, target_month: 1)
    assert_response :success
    assert_select "select[name='budget_copy[source_month]'] option[selected]", text: "December"
    assert_select "input[name='budget_copy[source_year]'][value='2025']"
  end

  # create

  test "create copies budgets from source month to target month" do
    assert_difference("Budget.count", 2) do
      post budget_copy_path, params: {
        budget_copy: { target_year: 2026, target_month: 5, source_year: 2026, source_month: 1 }
      }
    end
    assert_redirected_to budgets_path(year: 2026, month: 5)
    follow_redirect!
    assert_select "div", /Copied 2 budgets from January 2026/
  end

  test "create preserves amount_limit from source budgets" do
    post budget_copy_path, params: {
      budget_copy: { target_year: 2026, target_month: 5, source_year: 2026, source_month: 1 }
    }
    copied = Budget.find_by(category: categories(:groceries), year: 2026, month: 5)
    assert_not_nil copied
    assert_equal @groceries_january.amount_limit, copied.amount_limit
  end

  test "create skips budgets that already exist in target month" do
    # April already has groceries budget, copy from January (groceries + utilities)
    assert_difference("Budget.count", 1) do
      post budget_copy_path, params: {
        budget_copy: { target_year: 2026, target_month: 4, source_year: 2026, source_month: 1 }
      }
    end
    assert_redirected_to budgets_path(year: 2026, month: 4)
    follow_redirect!
    assert_select "div", /1 already existed and was skipped/
  end

  test "create redirects back with alert when source month has no budgets" do
    assert_no_difference("Budget.count") do
      post budget_copy_path, params: {
        budget_copy: { target_year: 2026, target_month: 5, source_year: 2020, source_month: 6 }
      }
    end
    assert_redirected_to new_budget_copy_path(target_year: 2026, target_month: 5)
    follow_redirect!
    assert_select "div", /No budgets found for June 2020/
  end
end
