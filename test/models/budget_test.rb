require "test_helper"

class BudgetTest < ActiveSupport::TestCase
  # Validations

  test "valid budget" do
    budget = Budget.new(category: categories(:dining), year: 2026, month: 3, amount_limit: 200)
    assert budget.valid?
  end

  test "requires year" do
    budget = Budget.new(category: categories(:groceries), month: 1, amount_limit: 100)
    assert_not budget.valid?
    assert_includes budget.errors[:year], "can't be blank"
  end

  test "requires year to be integer" do
    budget = Budget.new(category: categories(:dining), year: 2026.5, month: 1, amount_limit: 100)
    assert_not budget.valid?
    assert_includes budget.errors[:year], "must be an integer"
  end

  test "requires year >= 2000" do
    budget = Budget.new(category: categories(:dining), year: 1999, month: 1, amount_limit: 100)
    assert_not budget.valid?
    assert_includes budget.errors[:year], "must be greater than or equal to 2000"
  end

  test "requires month" do
    budget = Budget.new(category: categories(:groceries), year: 2026, amount_limit: 100)
    assert_not budget.valid?
    assert_includes budget.errors[:month], "can't be blank"
  end

  test "rejects month outside 1..12" do
    budget = Budget.new(category: categories(:dining), year: 2026, month: 13, amount_limit: 100)
    assert_not budget.valid?
    assert_includes budget.errors[:month], "is not included in the list"
  end

  test "requires amount_limit" do
    budget = Budget.new(category: categories(:groceries), year: 2026, month: 3)
    assert_not budget.valid?
    assert_includes budget.errors[:amount_limit], "can't be blank"
  end

  test "requires amount_limit > 0" do
    budget = Budget.new(category: categories(:dining), year: 2026, month: 3, amount_limit: 0)
    assert_not budget.valid?
    assert_includes budget.errors[:amount_limit], "must be greater than 0"
  end

  test "enforces uniqueness of category_id scoped to year and month" do
    existing = budgets(:groceries_january)
    duplicate = Budget.new(
      category: existing.category,
      year: existing.year,
      month: existing.month,
      amount_limit: 999
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:category_id], "has already been taken"
  end

  test "allows same category in different months" do
    budget = Budget.new(category: categories(:groceries), year: 2026, month: 6, amount_limit: 300)
    assert budget.valid?
  end

  # spent

  test "spent returns sum of expense transactions for the category in the budget month" do
    budget = budgets(:groceries_january)
    # grocery_january fixture: amount=150, checking, Jan 2026, category=groceries
    assert_equal 150, budget.spent
  end

  test "spent returns 0 when no transactions exist" do
    budget = Budget.new(category: categories(:dining), year: 2026, month: 1, amount_limit: 200)
    budget.save!
    assert_equal 0, budget.spent
  end

  # remaining

  test "remaining returns amount_limit minus spent" do
    budget = budgets(:groceries_january)
    assert_equal budget.amount_limit - budget.spent, budget.remaining
  end

  # percent_used

  test "percent_used computes correctly" do
    budget = budgets(:groceries_january)
    # spent=150, limit=300 → 50%
    assert_equal 50, budget.percent_used
  end

  test "percent_used clamps at 100" do
    budget = budgets(:utilities_january)
    # utility_january: amount=80, limit=150 → ~53.3%, under 100
    # Let's create a scenario with overspend instead
    budget.update!(amount_limit: 50)
    # spent=80, limit=50 → 160% clamped to 100
    assert_equal 100, budget.percent_used
  end

  test "percent_used returns 0 when no spend" do
    budget = Budget.create!(category: categories(:dining), year: 2026, month: 1, amount_limit: 200)
    assert_equal 0, budget.percent_used
  end

  # over_budget?

  test "over_budget? returns true when spent exceeds limit" do
    budget = budgets(:utilities_january)
    budget.update!(amount_limit: 50)
    # spent=80, limit=50
    assert budget.over_budget?
  end

  test "over_budget? returns false when under limit" do
    budget = budgets(:groceries_january)
    # spent=150, limit=300
    assert_not budget.over_budget?
  end
end
