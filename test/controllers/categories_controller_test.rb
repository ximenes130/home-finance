require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @salary = categories(:salary)
    @groceries = categories(:groceries)
  end

  # index

  test "index lists all categories" do
    get categories_path
    assert_response :success
    assert_select "h1", "Categories"
  end

  test "index shows income and expense sections" do
    get categories_path
    assert_response :success
    assert_select "h2", "Income Categories"
    assert_select "h2", "Expense Categories"
  end

  test "index shows empty state when no categories exist" do
    Category.all.each { |c| c.transactions.delete_all; c.destroy! }
    get categories_path
    assert_response :success
    assert_select "h3", "No categories yet"
  end

  # new

  test "new renders the form" do
    get new_category_path
    assert_response :success
    assert_select "form"
  end

  # create

  test "create with valid params creates category and redirects" do
    assert_difference("Category.count", 1) do
      post categories_path, params: { category: { name: "Investments", kind: "income" } }
    end
    assert_redirected_to categories_path
    follow_redirect!
    assert_select "div", /Category was successfully created/
  end

  test "create with invalid params renders new with errors" do
    assert_no_difference("Category.count") do
      post categories_path, params: { category: { name: "", kind: "expense" } }
    end
    assert_response :unprocessable_entity
    assert_select "form"
  end

  test "create with duplicate name in same kind is rejected" do
    assert_no_difference("Category.count") do
      post categories_path, params: { category: { name: @salary.name, kind: @salary.kind } }
    end
    assert_response :unprocessable_entity
  end

  test "create with same name in different kind is allowed" do
    assert_difference("Category.count", 1) do
      post categories_path, params: { category: { name: @salary.name, kind: "expense" } }
    end
    assert_redirected_to categories_path
  end

  # edit

  test "edit renders the form" do
    get edit_category_path(@salary)
    assert_response :success
    assert_select "form"
  end

  # update

  test "update with valid params updates category and redirects" do
    patch category_path(@salary), params: { category: { name: "Updated Salary" } }
    assert_redirected_to categories_path
    assert_equal "Updated Salary", @salary.reload.name
  end

  test "update with invalid params renders edit with errors" do
    patch category_path(@salary), params: { category: { name: "" } }
    assert_response :unprocessable_entity
    assert_select "form"
  end

  # destroy

  test "destroy deletable category removes it and redirects" do
    deletable = Category.create!(name: "Temporary", kind: "expense")
    assert_difference("Category.count", -1) do
      delete category_path(deletable)
    end
    assert_redirected_to categories_path
  end

  test "destroy non-deletable category redirects with alert" do
    assert_no_difference("Category.count") do
      delete category_path(@groceries)
    end
    assert_redirected_to categories_path
    follow_redirect!
    assert_select "div", /Cannot delete category with transactions/
  end
end
