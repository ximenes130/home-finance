class Accounts::ActivationsController < ApplicationController
  before_action :set_account

  def create
    @account.activate
    redirect_to @account, notice: "#{@account.name} has been reactivated."
  end

  def destroy
    @account.deactivate
    redirect_to @account, notice: "#{@account.name} has been deactivated."
  end

  private
    def set_account
      @account = Account.find(params[:account_id])
    end
end
