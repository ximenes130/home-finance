require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  # Validations

  test "valid category" do
    category = Category.new(name: "Transport", kind: "expense")
    assert category.valid?
  end

  test "requires name" do
    category = Category.new(kind: "expense")
    assert_not category.valid?
    assert_includes category.errors[:name], "can't be blank"
  end

  test "requires kind" do
    category = Category.new(name: "Test")
    assert_not category.valid?
    assert_includes category.errors[:kind], "can't be blank"
  end

  test "rejects invalid kind" do
    category = Category.new(name: "Test", kind: "transfer")
    assert_not category.valid?
    assert_includes category.errors[:kind], "is not included in the list"
  end

  test "allows duplicate name across different kinds" do
    Category.create!(name: "Bonus", kind: "income")
    duplicate = Category.new(name: "Bonus", kind: "expense")
    assert duplicate.valid?
  end

  test "rejects duplicate name within same kind" do
    Category.create!(name: "Unique", kind: "expense")
    duplicate = Category.new(name: "Unique", kind: "expense")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  # Scopes

  test "income scope returns income categories" do
    income_categories = Category.income
    assert income_categories.all? { |c| c.kind == "income" }
    assert_includes income_categories, categories(:salary)
  end

  test "expense scope returns expense categories" do
    expense_categories = Category.expense
    assert expense_categories.all? { |c| c.kind == "expense" }
    assert_includes expense_categories, categories(:groceries)
  end

  # deletable?

  test "deletable? returns false when category has transactions" do
    assert_not categories(:groceries).deletable?
  end

  test "deletable? returns true when category has no transactions" do
    category = categories(:freelance)
    assert category.deletable?
  end

  # dependent: restrict_with_error

  test "cannot destroy category with transactions" do
    category = categories(:groceries)
    assert_not category.destroy
    assert_includes category.errors[:base], "Cannot delete record because dependent transactions exist"
  end

  # dependent: destroy on budgets

  test "destroying category destroys associated budgets" do
    category = categories(:freelance)
    category.budgets.create!(year: 2026, month: 3, amount_limit: 100)
    assert_difference "Budget.count", -1 do
      category.destroy
    end
  end
end
