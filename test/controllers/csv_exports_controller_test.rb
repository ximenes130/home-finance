require "test_helper"
require "csv"

class CsvExportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @checking = accounts(:checking)
    @savings = accounts(:savings)
    @salary = categories(:salary)
    @groceries = categories(:groceries)
  end

  # new

  test "new renders the export form" do
    get new_csv_export_path
    assert_response :success
    assert_select "h1", "Export Transactions"
    assert_select "form"
    assert_select "select[name=account_id]"
    assert_select "select[name=category_id]"
    assert_select "input[name=start_date]"
    assert_select "input[name=end_date]"
  end

  # create

  test "create returns a CSV file download" do
    post csv_exports_path
    assert_response :success
    assert_equal "text/csv; charset=utf-8", response.content_type
    assert_match "attachment", response.headers["Content-Disposition"]
    assert_match "home-finance-export-", response.headers["Content-Disposition"]
    assert_match ".csv", response.headers["Content-Disposition"]
  end

  test "create CSV has correct headers" do
    post csv_exports_path
    csv = CSV.parse(response.body, headers: true)
    assert_equal %w[date account kind category amount note], csv.headers
  end

  test "create with date filter exports only matching transactions" do
    post csv_exports_path, params: { start_date: "2026-01-01", end_date: "2026-01-31" }
    csv = CSV.parse(response.body, headers: true)

    csv.each do |row|
      date = Date.parse(row["date"])
      assert date >= Date.new(2026, 1, 1), "Expected date >= 2026-01-01, got #{date}"
      assert date <= Date.new(2026, 1, 31), "Expected date <= 2026-01-31, got #{date}"
    end

    assert csv.length > 0, "Expected at least one transaction in January"
  end

  test "create with account filter exports only that account's transactions" do
    post csv_exports_path, params: { account_id: @savings.id }
    csv = CSV.parse(response.body, headers: true)

    csv.each do |row|
      assert_equal @savings.name, row["account"]
    end
  end

  test "create with category filter exports only that category's transactions" do
    post csv_exports_path, params: { category_id: @groceries.id }
    csv = CSV.parse(response.body, headers: true)

    csv.each do |row|
      assert_equal @groceries.name, row["category"]
    end

    assert csv.length > 0, "Expected at least one grocery transaction"
  end

  test "create with no filters exports all transactions" do
    post csv_exports_path
    csv = CSV.parse(response.body, headers: true)
    assert_equal Transaction.count, csv.length
  end

  test "create CSV rows are sorted by date ascending" do
    post csv_exports_path
    csv = CSV.parse(response.body, headers: true)

    dates = csv.map { |row| Date.parse(row["date"]) }
    assert_equal dates.sort, dates
  end

  test "create CSV contains correct data for a known transaction" do
    post csv_exports_path, params: { start_date: "2026-04-01", end_date: "2026-04-01" }
    csv = CSV.parse(response.body, headers: true)

    salary_row = csv.find { |row| row["note"] == "April salary" }
    assert_not_nil salary_row
    assert_equal "2026-04-01", salary_row["date"]
    assert_equal @checking.name, salary_row["account"]
    assert_equal "income", salary_row["kind"]
    assert_equal @salary.name, salary_row["category"]
    assert_equal "3500.0", salary_row["amount"]
  end

  test "create with no matching transactions returns CSV with only headers" do
    post csv_exports_path, params: { start_date: "2099-01-01", end_date: "2099-12-31" }
    csv = CSV.parse(response.body, headers: true)
    assert_equal 0, csv.length
    assert_equal %w[date account kind category amount note], csv.headers
  end
end
