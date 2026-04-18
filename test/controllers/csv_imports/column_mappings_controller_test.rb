require "test_helper"

class CsvImports::ColumnMappingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @checking = accounts(:checking)
    @csv_import = CsvImport.create!(account: @checking, filename: "test.csv")
    @csv_import.file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample_transactions.csv")),
      filename: "sample_transactions.csv",
      content_type: "text/csv"
    )
  end

  test "show displays column mapping form with auto-detected columns" do
    get csv_import_column_mapping_path(@csv_import)
    assert_response :success
    assert_select "select[name='column_mapping[transaction_date]']"
    assert_select "select[name='column_mapping[amount]']"
  end

  test "show displays preview rows" do
    get csv_import_column_mapping_path(@csv_import)
    assert_response :success
    assert_select "table tbody tr", count: 5
  end

  test "update saves mapping and redirects to confirmation" do
    patch csv_import_column_mapping_path(@csv_import), params: {
      column_mapping: {
        transaction_date: "Date",
        amount: "Amount",
        category: "Category",
        note: "Description"
      }
    }

    assert_redirected_to csv_import_confirmation_path(@csv_import)
    @csv_import.reload
    assert_equal "Date", @csv_import.column_mapping["transaction_date"]
    assert_equal "Amount", @csv_import.column_mapping["amount"]
  end
end
