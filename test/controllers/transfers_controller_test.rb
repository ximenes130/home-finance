require "test_helper"

class TransfersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @checking = accounts(:checking)
    @savings = accounts(:savings)
  end

  # new

  test "new renders the transfer form" do
    get new_transfer_path
    assert_response :success
    assert_select "h1", "New Transfer"
    assert_select "form"
  end

  # create

  test "create with valid params creates two linked transactions" do
    assert_difference("Transaction.count", 2) do
      post transfers_path, params: {
        transfer: {
          source_account_id: @checking.id,
          destination_account_id: @savings.id,
          amount: 250.00,
          transaction_date: "2026-04-18",
          note: "Monthly savings"
        }
      }
    end
    assert_redirected_to transactions_path
    follow_redirect!
    assert_select "div", /Transfer was successfully created/
  end

  test "create generates matching transfer_pair_id for both transactions" do
    post transfers_path, params: {
      transfer: {
        source_account_id: @checking.id,
        destination_account_id: @savings.id,
        amount: 300.00,
        transaction_date: "2026-04-18"
      }
    }

    source_tx = Transaction.where(account_id: @checking.id, amount: 300.00)
                           .where.not(transfer_pair_id: nil).order(:created_at).last
    dest_tx = Transaction.where(account_id: @savings.id, amount: 300.00)
                         .where.not(transfer_pair_id: nil).order(:created_at).last

    assert_not_nil source_tx
    assert_not_nil dest_tx
    assert_equal source_tx.transfer_pair_id, dest_tx.transfer_pair_id
  end

  test "create sets expense on source and income on destination" do
    post transfers_path, params: {
      transfer: {
        source_account_id: @checking.id,
        destination_account_id: @savings.id,
        amount: 100.00,
        transaction_date: "2026-04-18"
      }
    }

    source_tx = Transaction.where(account_id: @checking.id, amount: 100.00, kind: "expense")
                           .where.not(transfer_pair_id: nil).order(:created_at).last
    dest_tx = Transaction.where(account_id: @savings.id, amount: 100.00, kind: "income")
                         .where.not(transfer_pair_id: nil).order(:created_at).last

    assert_not_nil source_tx, "Source transaction should be an expense"
    assert_not_nil dest_tx, "Destination transaction should be income"
  end

  test "create with same source and destination renders error" do
    assert_no_difference("Transaction.count") do
      post transfers_path, params: {
        transfer: {
          source_account_id: @checking.id,
          destination_account_id: @checking.id,
          amount: 100.00,
          transaction_date: "2026-04-18"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "create with missing accounts renders error" do
    assert_no_difference("Transaction.count") do
      post transfers_path, params: {
        transfer: {
          source_account_id: "",
          destination_account_id: "",
          amount: 100.00,
          transaction_date: "2026-04-18"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "create with missing amount renders error" do
    assert_no_difference("Transaction.count") do
      post transfers_path, params: {
        transfer: {
          source_account_id: @checking.id,
          destination_account_id: @savings.id,
          amount: "",
          transaction_date: "2026-04-18"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "create without note succeeds" do
    assert_difference("Transaction.count", 2) do
      post transfers_path, params: {
        transfer: {
          source_account_id: @checking.id,
          destination_account_id: @savings.id,
          amount: 50.00,
          transaction_date: "2026-04-18"
        }
      }
    end
    assert_redirected_to transactions_path
  end
end
