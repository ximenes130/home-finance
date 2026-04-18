require "test_helper"

class AccountTest < ActiveSupport::TestCase
  # Validations

  test "valid account" do
    account = Account.new(name: "Test Account", account_type: "checking", opening_balance: 100)
    assert account.valid?
  end

  test "requires name" do
    account = Account.new(account_type: "checking")
    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test "requires unique name case-insensitively" do
    Account.create!(name: "Checking", account_type: "checking")
    duplicate = Account.new(name: "checking", account_type: "savings")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "requires account_type" do
    account = Account.new(name: "Test")
    assert_not account.valid?
    assert_includes account.errors[:account_type], "can't be blank"
  end

  test "rejects invalid account_type" do
    account = Account.new(name: "Test", account_type: "investment")
    assert_not account.valid?
    assert_includes account.errors[:account_type], "is not included in the list"
  end

  test "accepts all valid account types" do
    %w[cash checking credit_card savings].each do |type|
      account = Account.new(name: "#{type} account", account_type: type, opening_balance: 0)
      assert account.valid?, "Expected #{type} to be valid"
    end
  end

  test "validates numericality of opening_balance" do
    account = Account.new(name: "Test", account_type: "checking", opening_balance: "abc")
    assert_not account.valid?
    assert_includes account.errors[:opening_balance], "is not a number"
  end

  test "defaults opening_balance to 0" do
    account = Account.create!(name: "Zero Balance", account_type: "cash")
    assert_equal 0, account.opening_balance
  end

  # Scopes

  test "active scope returns only active accounts" do
    active_accounts = Account.active
    assert active_accounts.all?(&:active?)
    assert_not_includes active_accounts, accounts(:inactive)
  end

  # Balance computation

  test "balance returns opening_balance when no transactions" do
    account = accounts(:cash)
    account.transactions.delete_all
    assert_equal account.opening_balance, account.balance
  end

  test "balance adds income and subtracts expenses" do
    account = accounts(:checking)
    # From fixtures: opening_balance=1000, income=3000 (salary_january) + 3500 (salary_april),
    # expenses=150 (grocery_january) + 80 (utility_january) + 500 (transfer_out) + 200 (grocery_february)
    #   + 120 (grocery_april) + 1000 (transfer_april_out)
    expected = 1000 + 3000 + 3500 - 150 - 80 - 500 - 200 - 120 - 1000
    assert_equal expected, account.balance
  end

  test "balance includes transfer income" do
    account = accounts(:savings)
    # opening_balance=5000, income=500 (transfer_in) + 1000 (transfer_april_in)
    assert_equal 6500, account.balance
  end

  # activate / deactivate

  test "deactivate sets active to false" do
    account = accounts(:checking)
    account.deactivate
    assert_not account.active?
  end

  test "activate sets active to true" do
    account = accounts(:inactive)
    account.activate
    assert account.active?
  end

  # deletable?

  test "deletable? returns false when account has transactions" do
    assert_not accounts(:checking).deletable?
  end

  test "deletable? returns true when account has no transactions" do
    account = accounts(:inactive)
    assert account.deletable?
  end

  # dependent: restrict_with_error

  test "cannot destroy account with transactions" do
    account = accounts(:checking)
    assert_not account.destroy
    assert_includes account.errors[:base], "Cannot delete record because dependent transactions exist"
  end
end
