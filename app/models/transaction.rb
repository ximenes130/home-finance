require "csv"

class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :category, optional: true
  belongs_to :csv_import, optional: true

  validates :kind, presence: true, inclusion: { in: %w[income expense transfer] }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :transaction_date, presence: true

  scope :income, -> { where(kind: "income") }
  scope :expense, -> { where(kind: "expense") }
  scope :transfer, -> { where(kind: "transfer") }
  scope :for_month, ->(year, month) { where(transaction_date: Date.new(year, month, 1)..Date.new(year, month, -1)) }
  scope :by_date, -> { order(transaction_date: :desc, created_at: :desc) }

  def self.to_csv(transactions)
    CSV.generate(headers: true) do |csv|
      csv << %w[date account kind category amount note]
      transactions.each do |tx|
        csv << [ tx.transaction_date, tx.account.name, tx.kind, tx.category&.name, tx.amount, tx.note ]
      end
    end
  end

  def transfer_pair
    if transfer_pair_id.present?
      self.class.where(transfer_pair_id: transfer_pair_id).where.not(id: id).first
    end
  end
end
