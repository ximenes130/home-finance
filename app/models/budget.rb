class Budget < ApplicationRecord
  belongs_to :category

  validates :year, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 2000 }
  validates :month, presence: true, inclusion: { in: 1..12 }
  validates :amount_limit, presence: true, numericality: { greater_than: 0 }
  validates :category_id, uniqueness: { scope: [ :year, :month ] }

  def spent
    category.transactions.expense.for_month(year, month).sum(:amount)
  end

  def remaining
    amount_limit - spent
  end

  def percent_used
    if amount_limit > 0
      (spent / amount_limit * 100).clamp(0, 100)
    else
      0
    end
  end

  def over_budget?
    spent > amount_limit
  end
end
