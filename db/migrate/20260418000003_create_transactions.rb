class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.references :account, null: false, foreign_key: true
      t.string :kind, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.date :transaction_date, null: false
      t.references :category, foreign_key: true
      t.text :note
      t.string :transfer_pair_id
      t.string :fingerprint
      t.references :csv_import, foreign_key: true

      t.timestamps
    end

    add_index :transactions, :transfer_pair_id
    add_index :transactions, :fingerprint
    add_index :transactions, :transaction_date
  end
end
