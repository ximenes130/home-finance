require "test_helper"

class CsvImports::ConfirmationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @checking = accounts(:checking)
    @csv_import = CsvImport.create!(account: @checking, filename: "test.csv")
    @csv_import.file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample_transactions.csv")),
      filename: "sample_transactions.csv",
      content_type: "text/csv"
    )
    @csv_import.update!(column_mapping: {
      "transaction_date" => "Date",
      "amount" => "Amount",
      "category" => "Category",
      "note" => "Description"
    })
  end

  test "show displays all rows with duplicate info" do
    get csv_import_confirmation_path(@csv_import)
    assert_response :success
    assert_select "table tbody tr", count: 8
  end

  test "show shows summary counts" do
    get csv_import_confirmation_path(@csv_import)
    assert_response :success
    # Should show total rows count
    assert_select "p.text-2xl", /8/
  end

  test "create imports selected rows and redirects to show" do
    assert_difference("Transaction.count", 3) do
      post csv_import_confirmation_path(@csv_import), params: {
        selected_rows: [ "0", "1", "2" ]
      }
    end

    assert_redirected_to csv_import_path(@csv_import)
    @csv_import.reload
    assert_equal "completed", @csv_import.status
    assert_equal 3, @csv_import.imported_count
    assert_equal 5, @csv_import.skipped_count
  end

  test "create with no rows selected imports nothing" do
    assert_no_difference("Transaction.count") do
      post csv_import_confirmation_path(@csv_import)
    end

    @csv_import.reload
    assert_equal "completed", @csv_import.status
    assert_equal 0, @csv_import.imported_count
    assert_equal 8, @csv_import.skipped_count
  end

  test "create detects duplicates by fingerprint" do
    # Import all rows first
    post csv_import_confirmation_path(@csv_import), params: {
      selected_rows: (0..7).to_a.map(&:to_s)
    }

    # Create another import with the same CSV
    csv_import2 = CsvImport.create!(account: @checking, filename: "test2.csv")
    csv_import2.file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/sample_transactions.csv")),
      filename: "sample_transactions.csv",
      content_type: "text/csv"
    )
    csv_import2.update!(column_mapping: @csv_import.column_mapping)

    # Check that duplicates are detected
    get csv_import_confirmation_path(csv_import2)
    assert_response :success
    # All 8 rows should now be flagged as duplicates
    assert_select "span", text: "Possible duplicate", count: 8
  end
end
