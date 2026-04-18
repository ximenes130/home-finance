require "test_helper"

class CsvImportTest < ActiveSupport::TestCase
  # Validations

  test "valid csv_import" do
    csv_import = CsvImport.new(account: accounts(:checking), filename: "test.csv")
    assert csv_import.valid?
  end

  test "requires filename" do
    csv_import = CsvImport.new(account: accounts(:checking))
    assert_not csv_import.valid?
    assert_includes csv_import.errors[:filename], "can't be blank"
  end

  test "requires status to be valid" do
    csv_import = CsvImport.new(account: accounts(:checking), filename: "test.csv", status: "invalid")
    assert_not csv_import.valid?
    assert_includes csv_import.errors[:status], "is not included in the list"
  end

  test "defaults status to pending" do
    csv_import = CsvImport.create!(account: accounts(:checking), filename: "test.csv")
    assert_equal "pending", csv_import.status
  end

  # Status methods

  test "pending? returns true for pending status" do
    assert csv_imports(:pending_import).pending?
  end

  test "completed? returns true for completed status" do
    assert csv_imports(:recent_import).completed?
  end

  test "failed? returns true for failed status" do
    csv_import = CsvImport.create!(account: accounts(:checking), filename: "bad.csv", status: "failed")
    assert csv_import.failed?
  end

  # mark_completed

  test "mark_completed updates status and counts" do
    csv_import = csv_imports(:pending_import)

    freeze_time do
      csv_import.mark_completed(imported_count: 15, skipped_count: 3, row_count: 18)

      assert_equal "completed", csv_import.status
      assert_equal 15, csv_import.imported_count
      assert_equal 3, csv_import.skipped_count
      assert_equal 18, csv_import.row_count
      assert_equal Time.current, csv_import.imported_at
    end
  end

  # Scopes

  test "recent scope orders by created_at desc" do
    imports = CsvImport.recent.to_a
    imports.each_cons(2) do |a, b|
      assert a.created_at >= b.created_at
    end
  end

  # Associations

  test "belongs to account" do
    assert_equal accounts(:checking), csv_imports(:recent_import).account
  end

  test "destroying csv_import nullifies associated transactions" do
    csv_import = csv_imports(:recent_import)
    txn = Transaction.create!(
      account: accounts(:checking),
      kind: "expense",
      amount: 25,
      transaction_date: Date.current,
      csv_import: csv_import
    )

    csv_import.destroy!
    txn.reload
    assert_nil txn.csv_import_id
  end

  # parse_csv

  test "parse_csv returns headers and rows from attached file" do
    csv_import = create_import_with_file
    headers, rows = csv_import.parse_csv

    assert_equal %w[Date Amount Description Category Type], headers
    assert_equal 8, rows.size
    assert_equal "2026-04-01", rows.first[0]
  end

  test "parse_csv returns empty arrays when no file attached" do
    csv_import = CsvImport.create!(account: accounts(:checking), filename: "test.csv")
    headers, rows = csv_import.parse_csv

    assert_equal [], headers
    assert_equal [], rows
  end

  # preview_rows

  test "preview_rows returns headers and limited rows" do
    csv_import = create_import_with_file
    headers, rows = csv_import.preview_rows(3)

    assert_equal %w[Date Amount Description Category Type], headers
    assert_equal 3, rows.size
  end

  # detect_columns

  test "detect_columns maps common header names" do
    csv_import = create_import_with_file
    mapping = csv_import.detect_columns

    assert_equal "Date", mapping["transaction_date"]
    assert_equal "Amount", mapping["amount"]
    assert_equal "Description", mapping["note"]
    assert_equal "Category", mapping["category"]
  end

  # generate_fingerprint

  test "generate_fingerprint creates consistent SHA256 hash" do
    csv_import = CsvImport.create!(account: accounts(:checking), filename: "test.csv")
    values = %w[2026-04-01 85.50 Groceries]

    fp1 = csv_import.generate_fingerprint(values)
    fp2 = csv_import.generate_fingerprint(values)

    assert_equal fp1, fp2
    assert_equal 64, fp1.length
  end

  test "generate_fingerprint differs for different values" do
    csv_import = CsvImport.create!(account: accounts(:checking), filename: "test.csv")

    fp1 = csv_import.generate_fingerprint(%w[2026-04-01 85.50])
    fp2 = csv_import.generate_fingerprint(%w[2026-04-02 85.50])

    assert_not_equal fp1, fp2
  end

  test "generate_fingerprint includes account_id" do
    import1 = CsvImport.create!(account: accounts(:checking), filename: "test.csv")
    import2 = CsvImport.create!(account: accounts(:savings), filename: "test.csv")

    fp1 = import1.generate_fingerprint(%w[2026-04-01 85.50])
    fp2 = import2.generate_fingerprint(%w[2026-04-01 85.50])

    assert_not_equal fp1, fp2
  end

  # process_import

  test "process_import creates transactions for selected rows" do
    csv_import = create_import_with_file
    csv_import.update!(column_mapping: {
      "transaction_date" => "Date",
      "amount" => "Amount",
      "category" => "Category",
      "note" => "Description"
    })

    assert_difference("Transaction.count", 3) do
      csv_import.process_import([ 0, 1, 2 ])
    end

    csv_import.reload
    assert_equal "completed", csv_import.status
    assert_equal 3, csv_import.imported_count
    assert_equal 5, csv_import.skipped_count
    assert_equal 8, csv_import.row_count
  end

  test "process_import sets fingerprints on created transactions" do
    csv_import = create_import_with_file
    csv_import.update!(column_mapping: {
      "transaction_date" => "Date",
      "amount" => "Amount",
      "note" => "Description"
    })

    csv_import.process_import([ 0 ])

    transaction = csv_import.transactions.first
    assert_not_nil transaction.fingerprint
    assert_equal 64, transaction.fingerprint.length
  end

  test "process_import links transactions to csv_import" do
    csv_import = create_import_with_file
    csv_import.update!(column_mapping: {
      "transaction_date" => "Date",
      "amount" => "Amount"
    })

    csv_import.process_import([ 0, 1 ])

    csv_import.transactions.each do |txn|
      assert_equal csv_import.id, txn.csv_import_id
    end
  end

  test "process_import determines income or expense from amount sign" do
    csv_content = "Date,Amount,Description\n2026-04-01,-85.50,Grocery\n2026-04-10,3500.00,Salary\n"
    csv_import = CsvImport.create!(account: accounts(:checking), filename: "signed.csv")
    csv_import.file.attach(io: StringIO.new(csv_content), filename: "signed.csv", content_type: "text/csv")
    csv_import.update!(column_mapping: {
      "transaction_date" => "Date",
      "amount" => "Amount",
      "note" => "Description"
    })

    csv_import.process_import([ 0, 1 ])

    transactions = csv_import.transactions.order(:transaction_date)
    expense = transactions.find_by(transaction_date: Date.new(2026, 4, 1))
    income = transactions.find_by(transaction_date: Date.new(2026, 4, 10))

    assert_equal "expense", expense.kind
    assert_equal "income", income.kind
  end

  # mark_failed

  test "mark_failed sets status to failed" do
    csv_import = csv_imports(:pending_import)
    csv_import.mark_failed
    assert_equal "failed", csv_import.reload.status
  end

  private
    def create_import_with_file
      csv_import = CsvImport.create!(account: accounts(:checking), filename: "sample_transactions.csv")
      csv_import.file.attach(
        io: File.open(Rails.root.join("test/fixtures/files/sample_transactions.csv")),
        filename: "sample_transactions.csv",
        content_type: "text/csv"
      )
      csv_import
    end
end
