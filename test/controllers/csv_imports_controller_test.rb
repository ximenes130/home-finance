require "test_helper"

class CsvImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @checking = accounts(:checking)
    @recent_import = csv_imports(:recent_import)
  end

  # index

  test "index lists csv imports" do
    get csv_imports_path
    assert_response :success
    assert_select "h1", "Import History"
  end

  test "index shows empty state when no imports" do
    CsvImport.destroy_all
    get csv_imports_path
    assert_response :success
    assert_select "p", /No imports yet/
  end

  # new

  test "new renders the upload form" do
    get new_csv_import_path
    assert_response :success
    assert_select "form"
    assert_select "select[name='csv_import[account_id]']"
    assert_select "input[type='file']"
  end

  # create

  test "create with valid file uploads and redirects to column mapping" do
    file = fixture_file_upload("sample_transactions.csv", "text/csv")

    assert_difference("CsvImport.count", 1) do
      post csv_imports_path, params: {
        csv_import: { account_id: @checking.id, file: file }
      }
    end

    csv_import = CsvImport.last
    assert_equal "sample_transactions.csv", csv_import.filename
    assert_equal @checking.id, csv_import.account_id
    assert_equal "pending", csv_import.status
    assert csv_import.file.attached?
    assert_redirected_to csv_import_column_mapping_path(csv_import)
  end

  test "create without file renders errors" do
    post csv_imports_path, params: {
      csv_import: { account_id: @checking.id }
    }
    assert_response :unprocessable_entity
  end

  test "create without account renders errors" do
    file = fixture_file_upload("sample_transactions.csv", "text/csv")

    post csv_imports_path, params: {
      csv_import: { account_id: "", file: file }
    }
    assert_response :unprocessable_entity
  end

  # show

  test "show displays completed import details" do
    get csv_import_path(@recent_import)
    assert_response :success
    assert_select "h1", /Import Complete/
  end

  test "show displays failed import" do
    failed = CsvImport.create!(account: @checking, filename: "bad.csv", status: "failed")
    get csv_import_path(failed)
    assert_response :success
    assert_select "h1", /Import Failed/
  end
end
