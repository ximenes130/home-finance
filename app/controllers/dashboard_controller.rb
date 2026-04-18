class DashboardController < ApplicationController
  def show
    @accounts = Account.active.order(:name)

    if @accounts.any?
      @total_balance = @accounts.sum(&:balance)

      current_month_transactions = Transaction.for_month(current_year, current_month)

      @month_income = current_month_transactions.income.sum(:amount)
      @month_expenses = current_month_transactions.expense.sum(:amount)
      @month_net = @month_income - @month_expenses
      @transaction_count = current_month_transactions.count

      @budgets = Budget.where(year: current_year, month: current_month)
                               .includes(:category)
                               .sort_by { |b| -b.percent_used }

      @recent_transactions = Transaction.includes(:account, :category)
                                        .by_date
                                        .limit(10)

      @top_categories = current_month_transactions
                          .expense
                          .joins(:category)
                          .group("categories.name")
                          .order("sum_amount DESC")
                          .limit(5)
                          .sum(:amount)
    end
  end

  private
    def current_year
      Date.current.year
    end

    def current_month
      Date.current.month
    end
end
