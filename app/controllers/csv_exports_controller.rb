require "csv"

class CsvExportsController < ApplicationController
  def new
    @accounts = Account.order(:name)
    @categories = Category.order(:kind, :name)
  end

  def create
    transactions = filtered_transactions
    csv_data = Transaction.to_csv(transactions)
    filename = "home-finance-export-#{Date.current.strftime('%Y-%m-%d')}.csv"

    send_data csv_data,
      filename: filename,
      type: "text/csv; charset=utf-8",
      disposition: "attachment"
  end

  private
    def filtered_transactions
      scope = Transaction.includes(:account, :category).order(transaction_date: :asc, created_at: :asc)

      if params[:account_id].present?
        scope = scope.where(account_id: params[:account_id])
      end

      if params[:category_id].present?
        scope = scope.where(category_id: params[:category_id])
      end

      if params[:start_date].present?
        scope = scope.where("transaction_date >= ?", Date.parse(params[:start_date]))
      end

      if params[:end_date].present?
        scope = scope.where("transaction_date <= ?", Date.parse(params[:end_date]))
      end

      scope
    end
end
