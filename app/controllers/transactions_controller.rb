class TransactionsController < ApplicationController
  before_action :set_transaction, only: [ :edit, :update, :destroy ]

  def index
    @accounts = Account.active.order(:name)
    @categories = Category.order(:kind, :name)

    scope = Transaction.includes(:account, :category).by_date
    @transactions = apply_filters(scope)
  end

  def new
    @transaction = Transaction.new(transaction_date: Date.current, kind: "expense")
    load_form_options
  end

  def create
    @transaction = Transaction.new(transaction_params)

    if @transaction.save
      redirect_to transactions_path, notice: "Transaction was successfully created."
    else
      load_form_options
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_form_options
  end

  def update
    permitted = if @transaction.transfer_pair_id.present?
      params.require(:transaction).permit(:transaction_date, :note)
    else
      transaction_params
    end

    if @transaction.update(permitted)
      if @transaction.transfer_pair_id.present? && (pair = @transaction.transfer_pair)
        pair.update(transaction_date: @transaction.transaction_date, note: @transaction.note)
      end
      redirect_to transactions_path, notice: "Transaction was successfully updated."
    else
      load_form_options
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      if @transaction.transfer_pair_id.present? && (pair = @transaction.transfer_pair)
        pair.destroy!
      end
      @transaction.destroy!
    end

    redirect_to transactions_path, notice: "Transaction was successfully deleted."
  end

  private
    def set_transaction
      @transaction = Transaction.find(params[:id])
    end

    def load_form_options
      @accounts = Account.active.order(:name)
      @categories = Category.order(:kind, :name)
    end

    def transaction_params
      params.require(:transaction).permit(:account_id, :kind, :amount, :transaction_date, :category_id, :note)
    end

    def apply_filters(scope)
      if params[:account_id].present?
        scope = scope.where(account_id: params[:account_id])
      end

      if params[:category_id].present?
        scope = scope.where(category_id: params[:category_id])
      end

      if params[:kind].present?
        if params[:kind] == "transfer"
          scope = scope.where.not(transfer_pair_id: nil)
        else
          scope = scope.where(kind: params[:kind], transfer_pair_id: nil)
        end
      end

      start_date = if params[:start_date].present?
        Date.parse(params[:start_date])
      else
        Date.current.beginning_of_month
      end

      end_date = if params[:end_date].present?
        Date.parse(params[:end_date])
      else
        Date.current.end_of_month
      end

      scope.where(transaction_date: start_date..end_date)
    end
end
