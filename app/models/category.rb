class Category < ApplicationRecord
  has_many :transactions, dependent: :restrict_with_error
  has_many :budgets, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :kind }
  validates :kind, presence: true, inclusion: { in: %w[income expense] }

  scope :income, -> { where(kind: "income") }
  scope :expense, -> { where(kind: "expense") }

  def deletable?
    transactions.none?
  end
end
