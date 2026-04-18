class BudgetCopiesController < ApplicationController
  def new
    @target_year = (params[:target_year] || Date.current.year).to_i
    @target_month = (params[:target_month] || Date.current.month).to_i
    prev_month = Date.new(@target_year, @target_month, 1).prev_month
    @source_year = prev_month.year
    @source_month = prev_month.month
  end

  def create
    target_year = copy_params[:target_year].to_i
    target_month = copy_params[:target_month].to_i
    source_year = copy_params[:source_year].to_i
    source_month = copy_params[:source_month].to_i

    source_budgets = Budget.where(year: source_year, month: source_month)

    if source_budgets.empty?
      redirect_to new_budget_copy_path(target_year: target_year, target_month: target_month),
        alert: "No budgets found for #{Date.new(source_year, source_month).strftime('%B %Y')}."
      return
    end

    copied = 0
    skipped = 0

    source_budgets.each do |budget|
      new_budget = Budget.new(
        category_id: budget.category_id,
        year: target_year,
        month: target_month,
        amount_limit: budget.amount_limit
      )

      if new_budget.save
        copied += 1
      else
        skipped += 1
      end
    end

    msg = "Copied #{copied} budget#{copied != 1 ? 's' : ''} from #{Date.new(source_year, source_month).strftime('%B %Y')}"
    msg += "; #{skipped} already existed and #{skipped == 1 ? 'was' : 'were'} skipped" if skipped > 0

    redirect_to budgets_path(year: target_year, month: target_month), notice: "#{msg}."
  end

  private
    def copy_params
      params.require(:budget_copy).permit(:target_year, :target_month, :source_year, :source_month)
    end
end
