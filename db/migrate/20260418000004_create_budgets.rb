class CreateBudgets < ActiveRecord::Migration[8.1]
  def change
    create_table :budgets do |t|
      t.references :category, null: false, foreign_key: true
      t.integer :year, null: false
      t.integer :month, null: false
      t.decimal :amount_limit, precision: 12, scale: 2, null: false

      t.timestamps
    end

    add_index :budgets, [ :category_id, :year, :month ], unique: true
  end
end
