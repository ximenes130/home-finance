require "csv"
require "digest"

class CsvImport < ApplicationRecord
  belongs_to :account
  has_many :transactions, dependent: :nullify
  has_one_attached :file

  serialize :column_mapping, coder: JSON

  validates :filename, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending completed failed] }

  scope :recent, -> { order(created_at: :desc) }

  TRANSACTION_FIELDS = %w[transaction_date amount category note].freeze

  COLUMN_ALIASES = {
    "transaction_date" => %w[date transaction_date trans_date transactiondate posting_date post_date],
    "amount" => %w[amount value sum total debit credit],
    "category" => %w[category type category_name categoryname],
    "note" => %w[note description memo details narrative reference]
  }.freeze

  def completed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end

  def pending?
    status == "pending"
  end

  def mark_completed(imported_count:, skipped_count:, row_count:)
    update!(
      status: "completed",
      imported_at: Time.current,
      imported_count: imported_count,
      skipped_count: skipped_count,
      row_count: row_count
    )
  end

  def mark_failed
    update!(status: "failed")
  end

  def parse_csv
    return [ [], [] ] unless file.attached?

    content = file.download.force_encoding("UTF-8").encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    parsed = CSV.parse(content, headers: true, liberal_parsing: true)
    headers = parsed.headers.compact
    rows = parsed.map { |row| row.fields }

    [ headers, rows ]
  end

  def preview_rows(limit = 5)
    headers, rows = parse_csv
    [ headers, rows.first(limit) ]
  end

  def detect_columns
    headers, _ = parse_csv
    mapping = {}

    COLUMN_ALIASES.each do |field, aliases|
      matched = headers.find { |h| aliases.include?(h.to_s.strip.downcase.gsub(/\s+/, "_")) }
      if matched
        mapping[field] = matched
      end
    end

    mapping
  end

  def generate_fingerprint(row_values)
    raw = row_values.map(&:to_s).join("|") + "|#{account_id}"
    Digest::SHA256.hexdigest(raw)
  end

  def find_duplicates
    headers, rows = parse_csv
    mapping = column_mapping || {}
    duplicates = {}

    rows.each_with_index do |row, index|
      mapped_values = extract_mapped_values(headers, row, mapping)
      fingerprint = generate_fingerprint(mapped_values.values)
      existing = Transaction.where(account_id: account_id, fingerprint: fingerprint).exists?

      if existing
        duplicates[index] = true
      end
    end

    duplicates
  end

  def process_import(selected_row_indices)
    headers, rows = parse_csv
    mapping = column_mapping || {}
    imported = 0
    skipped = 0

    ActiveRecord::Base.transaction do
      rows.each_with_index do |row, index|
        unless selected_row_indices.include?(index)
          skipped += 1
          next
        end

        mapped = extract_mapped_values(headers, row, mapping)
        fingerprint = generate_fingerprint(mapped.values)

        transaction = build_transaction(mapped, fingerprint)

        if transaction.save
          imported += 1
        else
          skipped += 1
        end
      end

      mark_completed(imported_count: imported, skipped_count: skipped, row_count: rows.size)
    end
  end

  private
    def extract_mapped_values(headers, row, mapping)
      result = {}
      mapping.each do |field, csv_column|
        col_index = headers.index(csv_column)
        if col_index
          result[field] = row[col_index]
        end
      end
      result
    end

    def build_transaction(mapped, fingerprint)
      amount_raw = mapped["amount"].to_s.gsub(/[^0-9.\-]/, "")
      amount_value = BigDecimal(amount_raw) rescue BigDecimal("0")

      kind = if amount_value < 0
        "expense"
      else
        "income"
      end

      category = if mapped["category"].present?
        Category.find_by("LOWER(name) = ?", mapped["category"].strip.downcase)
      end

      date = begin
        Date.parse(mapped["transaction_date"].to_s)
      rescue ArgumentError, TypeError
        Date.current
      end

      account.transactions.build(
        kind: kind,
        amount: amount_value.abs,
        transaction_date: date,
        category: category,
        note: mapped["note"],
        csv_import: self,
        fingerprint: fingerprint
      )
    end
end
