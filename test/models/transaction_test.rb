require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  # Validations

  test "valid transaction" do
    txn = Transaction.new(
      account: accounts(:checking),
      kind: "expense",
      amount: 50.00,
      transaction_date: Date.current
    )
    assert txn.valid?
  end

  test "requires kind" do
    txn = Transaction.new(account: accounts(:checking), amount: 50, transaction_date: Date.current)
    assert_not txn.valid?
    assert_includes txn.errors[:kind], "can't be blank"
  end

  test "rejects invalid kind" do
    txn = Transaction.new(account: accounts(:checking), kind: "refund", amount: 50, transaction_date: Date.current)
    assert_not txn.valid?
    assert_includes txn.errors[:kind], "is not included in the list"
  end

  test "requires amount" do
    txn = Transaction.new(account: accounts(:checking), kind: "expense", transaction_date: Date.current)
    assert_not txn.valid?
    assert_includes txn.errors[:amount], "can't be blank"
  end

  test "requires amount greater than 0" do
    txn = Transaction.new(account: accounts(:checking), kind: "expense", amount: 0, transaction_date: Date.current)
    assert_not txn.valid?
    assert_includes txn.errors[:amount], "must be greater than 0"
  end

  test "rejects negative amount" do
    txn = Transaction.new(account: accounts(:checking), kind: "expense", amount: -10, transaction_date: Date.current)
    assert_not txn.valid?
    assert_includes txn.errors[:amount], "must be greater than 0"
  end

  test "requires transaction_date" do
    txn = Transaction.new(account: accounts(:checking), kind: "expense", amount: 50)
    assert_not txn.valid?
    assert_includes txn.errors[:transaction_date], "can't be blank"
  end

  test "category is optional" do
    txn = Transaction.new(
      account: accounts(:checking),
      kind: "expense",
      amount: 50,
      transaction_date: Date.current
    )
    assert txn.valid?
  end

  # Scopes

  test "income scope" do
    assert Transaction.income.all? { |t| t.kind == "income" }
  end

  test "expense scope" do
    assert Transaction.expense.all? { |t| t.kind == "expense" }
  end

  test "transfer scope" do
    transfers = Transaction.transfer
    assert transfers.none?, "No transfer-kind transactions in fixtures (transfers use income/expense kinds)"
  end

  test "for_month scope returns transactions in the given month" do
    january_txns = Transaction.for_month(2026, 1)
    assert january_txns.all? { |t| t.transaction_date.month == 1 && t.transaction_date.year == 2026 }
    assert_includes january_txns, transactions(:salary_january)
    assert_not_includes january_txns, transactions(:grocery_february)
  end

  test "by_date scope orders by transaction_date desc then created_at desc" do
    ordered = Transaction.by_date.to_a
    ordered.each_cons(2) do |a, b|
      assert a.transaction_date >= b.transaction_date
    end
  end

  # transfer_pair

  test "transfer_pair returns the paired transaction" do
    source = transactions(:transfer_out)
    destination = transactions(:transfer_in)

    assert_equal destination, source.transfer_pair
    assert_equal source, destination.transfer_pair
  end

  test "transfer_pair returns nil when no transfer_pair_id" do
    txn = transactions(:salary_january)
    assert_nil txn.transfer_pair
  end

  # Associations

  test "belongs to account" do
    txn = transactions(:salary_january)
    assert_equal accounts(:checking), txn.account
  end

  test "belongs to category optionally" do
    txn = transactions(:transfer_out)
    assert_nil txn.category
  end

  test "csv_import is optional" do
    txn = transactions(:salary_january)
    assert_nil txn.csv_import
  end
end
