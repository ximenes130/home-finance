class TransfersController < ApplicationController
  def new
    @accounts = Account.active.order(:name)
  end

  def create
    @accounts = Account.active.order(:name)

    source_id = transfer_params[:source_account_id]
    destination_id = transfer_params[:destination_account_id]
    amount = transfer_params[:amount]
    date = transfer_params[:transaction_date]
    note = transfer_params[:note]

    if source_id.blank? || destination_id.blank?
      flash.now[:alert] = "Please select both source and destination accounts."
      return render :new, status: :unprocessable_entity
    end

    if source_id == destination_id
      flash.now[:alert] = "Source and destination accounts must be different."
      return render :new, status: :unprocessable_entity
    end

    pair_id = SecureRandom.uuid

    ActiveRecord::Base.transaction do
      @source_transaction = Transaction.create!(
        account_id: source_id,
        kind: "expense",
        amount: amount,
        transaction_date: date,
        note: note,
        transfer_pair_id: pair_id
      )

      @destination_transaction = Transaction.create!(
        account_id: destination_id,
        kind: "income",
        amount: amount,
        transaction_date: date,
        note: note,
        transfer_pair_id: pair_id
      )
    end

    redirect_to transactions_path, notice: "Transfer was successfully created."
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.record.errors.full_messages.to_sentence
    render :new, status: :unprocessable_entity
  end

  private
    def transfer_params
      params.require(:transfer).permit(:source_account_id, :destination_account_id, :amount, :transaction_date, :note)
    end
end
