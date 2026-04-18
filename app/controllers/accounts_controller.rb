class AccountsController < ApplicationController
  before_action :set_account, only: [ :show, :edit, :update, :destroy ]

  def index
    @accounts = Account.order(active: :desc, name: :asc)
  end

  def show
    @recent_transactions = @account.transactions.order(transaction_date: :desc, created_at: :desc).limit(10)
  end

  def new
    @account = Account.new
  end

  def create
    @account = Account.new(account_params)

    if @account.save
      redirect_to accounts_path, notice: "Account was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @account.update(account_params)
      redirect_to @account, notice: "Account was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @account.deletable?
      @account.destroy!
      redirect_to accounts_path, notice: "Account was successfully deleted."
    else
      redirect_to @account, alert: "Cannot delete account with transactions. Deactivate it instead."
    end
  end

  private
    def set_account
      @account = Account.find(params[:id])
    end

    def account_params
      params.require(:account).permit(:name, :account_type, :opening_balance)
    end
end
