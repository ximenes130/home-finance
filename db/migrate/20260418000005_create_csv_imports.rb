class CreateCsvImports < ActiveRecord::Migration[8.1]
  def change
    create_table :csv_imports do |t|
      t.references :account, null: false, foreign_key: true
      t.string :filename, null: false
      t.integer :row_count, default: 0
      t.integer :imported_count, default: 0
      t.integer :skipped_count, default: 0
      t.string :status, null: false, default: "pending"
      t.datetime :imported_at

      t.timestamps
    end
  end
end
