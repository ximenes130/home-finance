require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @checking = accounts(:checking)
    @savings = accounts(:savings)
    @salary = categories(:salary)
    @groceries = categories(:groceries)
    @salary_april = transactions(:salary_april)
    @grocery_april = transactions(:grocery_april)
    @transfer_out = transactions(:transfer_april_out)
    @transfer_in = transactions(:transfer_april_in)
  end

  # index

  test "index lists transactions for current month" do
    get transactions_path
    assert_response :success
    assert_select "h1", "Transactions"
  end

  test "index defaults to current month date range" do
    get transactions_path
    assert_response :success
    # April 2026 transactions should appear
    assert_response :success
  end

  test "index filters by account" do
    get transactions_path(account_id: @checking.id, start_date: "2026-04-01", end_date: "2026-04-30")
    assert_response :success
  end

  test "index filters by category" do
    get transactions_path(category_id: @groceries.id, start_date: "2026-04-01", end_date: "2026-04-30")
    assert_response :success
  end

  test "index filters by kind income" do
    get transactions_path(kind: "income", start_date: "2026-04-01", end_date: "2026-04-30")
    assert_response :success
  end

  test "index filters by kind expense" do
    get transactions_path(kind: "expense", start_date: "2026-04-01", end_date: "2026-04-30")
    assert_response :success
  end

  test "index filters by kind transfer" do
    get transactions_path(kind: "transfer", start_date: "2026-04-01", end_date: "2026-04-30")
    assert_response :success
  end

  test "index filters by date range" do
    get transactions_path(start_date: "2026-01-01", end_date: "2026-01-31")
    assert_response :success
  end

  test "index responds within turbo frame" do
    get transactions_path, headers: { "Turbo-Frame" => "transactions" }
    assert_response :success
  end

  # new

  test "new renders the form" do
    get new_transaction_path
    assert_response :success
    assert_select "form"
  end

  # create

  test "create with valid income params creates transaction and redirects" do
    assert_difference("Transaction.count", 1) do
      post transactions_path, params: {
        transaction: {
          account_id: @checking.id,
          kind: "income",
          amount: 500.00,
          transaction_date: "2026-04-18",
          category_id: @salary.id,
          note: "Bonus"
        }
      }
    end
    assert_redirected_to transactions_path
    follow_redirect!
    assert_select "div", /Transaction was successfully created/
  end

  test "create with valid expense params creates transaction" do
    assert_difference("Transaction.count", 1) do
      post transactions_path, params: {
        transaction: {
          account_id: @checking.id,
          kind: "expense",
          amount: 50.00,
          transaction_date: "2026-04-18",
          category_id: @groceries.id
        }
      }
    end
    assert_redirected_to transactions_path
  end

  test "create with invalid params renders new with errors" do
    assert_no_difference("Transaction.count") do
      post transactions_path, params: {
        transaction: {
          account_id: @checking.id,
          kind: "expense",
          amount: "",
          transaction_date: ""
        }
      }
    end
    assert_response :unprocessable_entity
    assert_select "form"
  end

  test "create without category succeeds" do
    assert_difference("Transaction.count", 1) do
      post transactions_path, params: {
        transaction: {
          account_id: @checking.id,
          kind: "expense",
          amount: 20.00,
          transaction_date: "2026-04-18"
        }
      }
    end
    assert_redirected_to transactions_path
  end

  # edit

  test "edit renders the form for regular transaction" do
    get edit_transaction_path(@grocery_april)
    assert_response :success
    assert_select "form"
  end

  test "edit renders limited form for transfer transaction" do
    get edit_transaction_path(@transfer_out)
    assert_response :success
    assert_select "form"
  end

  # update

  test "update regular transaction with valid params" do
    patch transaction_path(@grocery_april), params: {
      transaction: { note: "Updated note", amount: 130.00 }
    }
    assert_redirected_to transactions_path
    assert_equal "Updated note", @grocery_april.reload.note
    assert_equal 130.00, @grocery_april.reload.amount
  end

  test "update transfer transaction only allows date and note" do
    original_amount = @transfer_out.amount
    patch transaction_path(@transfer_out), params: {
      transaction: { note: "Updated transfer note", transaction_date: "2026-04-06" }
    }
    assert_redirected_to transactions_path
    @transfer_out.reload
    assert_equal "Updated transfer note", @transfer_out.note
    assert_equal Date.parse("2026-04-06"), @transfer_out.transaction_date
    assert_equal original_amount, @transfer_out.amount
  end

  test "update transfer syncs changes to paired transaction" do
    patch transaction_path(@transfer_out), params: {
      transaction: { note: "Synced note", transaction_date: "2026-04-07" }
    }
    @transfer_in.reload
    assert_equal "Synced note", @transfer_in.note
    assert_equal Date.parse("2026-04-07"), @transfer_in.transaction_date
  end

  test "update with invalid params renders edit with errors" do
    patch transaction_path(@grocery_april), params: {
      transaction: { amount: "" }
    }
    assert_response :unprocessable_entity
    assert_select "form"
  end

  # destroy

  test "destroy regular transaction removes it" do
    transaction = transactions(:dining_april)
    assert_difference("Transaction.count", -1) do
      delete transaction_path(transaction)
    end
    assert_redirected_to transactions_path
  end

  test "destroy transfer removes both sides" do
    assert_difference("Transaction.count", -2) do
      delete transaction_path(@transfer_out)
    end
    assert_redirected_to transactions_path
    assert_nil Transaction.find_by(id: @transfer_in.id)
  end
end
