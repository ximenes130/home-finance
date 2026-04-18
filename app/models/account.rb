class Account < ApplicationRecord
  has_many :transactions, dependent: :restrict_with_error
  has_many :csv_imports, dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :account_type, presence: true, inclusion: { in: %w[cash checking credit_card savings] }
  validates :opening_balance, presence: true, numericality: true

  scope :active, -> { where(active: true) }

  def balance
    opening_balance + transactions.sum(
      "CASE WHEN kind = 'income' THEN amount WHEN kind = 'expense' THEN -amount ELSE 0 END"
    )
  end

  def deactivate
    update!(active: false)
  end

  def activate
    update!(active: true)
  end

  def deletable?
    transactions.none?
  end
end
