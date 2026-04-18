class BudgetsController < ApplicationController
  before_action :set_budget, only: [ :show, :edit, :update, :destroy ]

  def index
    @year = (params[:year] || Date.current.year).to_i
    @month = (params[:month] || Date.current.month).to_i

    @budgets = Budget.includes(:category)
                     .where(year: @year, month: @month)
                     .sort_by { |b| -b.percent_used }

    @total_budgeted = @budgets.sum(&:amount_limit)
    @total_spent = @budgets.sum(&:spent)
    @total_remaining = @total_budgeted - @total_spent
  end

  def show
    @transactions = Transaction.expense
                               .where(category_id: @budget.category_id)
                               .for_month(@budget.year, @budget.month)
                               .includes(:account)
                               .by_date
  end

  def new
    @budget = Budget.new(
      year: params[:year] || Date.current.year,
      month: params[:month] || Date.current.month
    )
  end

  def create
    @budget = Budget.new(budget_params)

    if @budget.save
      redirect_to budgets_path(year: @budget.year, month: @budget.month), notice: "Budget was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @budget.update(update_budget_params)
      redirect_to budgets_path(year: @budget.year, month: @budget.month), notice: "Budget was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    year = @budget.year
    month = @budget.month
    @budget.destroy!
    redirect_to budgets_path(year: year, month: month), notice: "Budget was successfully deleted."
  end

  private
    def set_budget
      @budget = Budget.find(params[:id])
    end

    def budget_params
      params.require(:budget).permit(:category_id, :year, :month, :amount_limit)
    end

    def update_budget_params
      params.require(:budget).permit(:amount_limit)
    end
end
