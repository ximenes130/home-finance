# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# -- Accounts --

wallet = Account.find_or_create_by!(name: "Wallet") do |a|
  a.account_type = "cash"
  a.opening_balance = 200.00
end

checking = Account.find_or_create_by!(name: "Main Checking") do |a|
  a.account_type = "checking"
  a.opening_balance = 5000.00
end

visa = Account.find_or_create_by!(name: "Visa Platinum") do |a|
  a.account_type = "credit_card"
  a.opening_balance = 0.00
end

savings = Account.find_or_create_by!(name: "Emergency Fund") do |a|
  a.account_type = "savings"
  a.opening_balance = 10_000.00
end

# -- Income Categories --

salary = Category.find_or_create_by!(name: "Salary", kind: "income")
freelance = Category.find_or_create_by!(name: "Freelance", kind: "income")
Category.find_or_create_by!(name: "Investments", kind: "income")
Category.find_or_create_by!(name: "Other Income", kind: "income")

# -- Expense Categories --

groceries   = Category.find_or_create_by!(name: "Groceries", kind: "expense")
dining      = Category.find_or_create_by!(name: "Dining Out", kind: "expense")
transport   = Category.find_or_create_by!(name: "Transportation", kind: "expense")
utilities   = Category.find_or_create_by!(name: "Utilities", kind: "expense")
entertainment = Category.find_or_create_by!(name: "Entertainment", kind: "expense")
health      = Category.find_or_create_by!(name: "Health", kind: "expense")
shopping    = Category.find_or_create_by!(name: "Shopping", kind: "expense")
education   = Category.find_or_create_by!(name: "Education", kind: "expense")
housing     = Category.find_or_create_by!(name: "Housing", kind: "expense")
subscriptions = Category.find_or_create_by!(name: "Subscriptions", kind: "expense")

# -- Transactions --
# Helper to create transactions idempotently based on unique attributes.

def seed_transaction(account:, kind:, amount:, date:, category: nil, note: nil, transfer_pair_id: nil)
  attrs = { account: account, kind: kind, amount: amount, transaction_date: date, note: note }
  attrs[:transfer_pair_id] = transfer_pair_id if transfer_pair_id

  Transaction.find_or_create_by!(attrs) do |t|
    t.category = category
  end
end

this_month = Date.current.beginning_of_month
last_month = (this_month - 1.month)

# --- Previous Month ---

# Salary — 1st and 15th
seed_transaction(account: checking, kind: "income", amount: 3500.00, date: last_month, category: salary, note: "Salary - first half")
seed_transaction(account: checking, kind: "income", amount: 3500.00, date: last_month + 14, category: salary, note: "Salary - second half")

# Freelance gig
seed_transaction(account: checking, kind: "income", amount: 850.00, date: last_month + 9, category: freelance, note: "Logo design project")

# Groceries
seed_transaction(account: checking, kind: "expense", amount: 87.50, date: last_month + 2, category: groceries, note: "Weekly groceries")
seed_transaction(account: checking, kind: "expense", amount: 62.30, date: last_month + 8, category: groceries, note: "Grocery run")
seed_transaction(account: visa, kind: "expense", amount: 104.20, date: last_month + 15, category: groceries, note: "Costco bulk shopping")

# Dining
seed_transaction(account: visa, kind: "expense", amount: 45.00, date: last_month + 5, category: dining, note: "Dinner with friends")
seed_transaction(account: wallet, kind: "expense", amount: 18.50, date: last_month + 12, category: dining, note: "Lunch at deli")

# Utilities
seed_transaction(account: checking, kind: "expense", amount: 185.00, date: last_month + 4, category: utilities, note: "Electric bill")
seed_transaction(account: checking, kind: "expense", amount: 65.00, date: last_month + 4, category: utilities, note: "Internet")

# Housing
seed_transaction(account: checking, kind: "expense", amount: 1500.00, date: last_month, category: housing, note: "Rent")

# Transportation
seed_transaction(account: visa, kind: "expense", amount: 55.00, date: last_month + 6, category: transport, note: "Gas station")
seed_transaction(account: checking, kind: "expense", amount: 120.00, date: last_month + 3, category: transport, note: "Car insurance")

# Entertainment
seed_transaction(account: visa, kind: "expense", amount: 32.00, date: last_month + 10, category: entertainment, note: "Movie tickets")

# Subscriptions
seed_transaction(account: visa, kind: "expense", amount: 15.99, date: last_month + 1, category: subscriptions, note: "Netflix")
seed_transaction(account: visa, kind: "expense", amount: 10.99, date: last_month + 1, category: subscriptions, note: "Spotify")

# Transfer: checking → savings
transfer_1_id = "seed-transfer-last-month-savings"
seed_transaction(account: checking, kind: "expense", amount: 500.00, date: last_month + 14, note: "Transfer to savings", transfer_pair_id: transfer_1_id)
seed_transaction(account: savings, kind: "income", amount: 500.00, date: last_month + 14, note: "Transfer from checking", transfer_pair_id: transfer_1_id)

# --- Current Month ---

# Salary — 1st and 15th
seed_transaction(account: checking, kind: "income", amount: 3500.00, date: this_month, category: salary, note: "Salary - first half")
if Date.current.day >= 15
  seed_transaction(account: checking, kind: "income", amount: 3500.00, date: this_month + 14, category: salary, note: "Salary - second half")
end

# Groceries
seed_transaction(account: checking, kind: "expense", amount: 95.40, date: this_month + 1, category: groceries, note: "Weekly groceries")
seed_transaction(account: visa, kind: "expense", amount: 78.60, date: this_month + 5, category: groceries, note: "Grocery store")
seed_transaction(account: checking, kind: "expense", amount: 112.30, date: this_month + 9, category: groceries, note: "Costco run")

# Dining
seed_transaction(account: visa, kind: "expense", amount: 67.50, date: this_month + 3, category: dining, note: "Birthday dinner")
seed_transaction(account: wallet, kind: "expense", amount: 22.00, date: this_month + 7, category: dining, note: "Coffee & pastry")

# Utilities
seed_transaction(account: checking, kind: "expense", amount: 195.00, date: this_month + 4, category: utilities, note: "Electric bill")
seed_transaction(account: checking, kind: "expense", amount: 65.00, date: this_month + 4, category: utilities, note: "Internet")

# Housing
seed_transaction(account: checking, kind: "expense", amount: 1500.00, date: this_month, category: housing, note: "Rent")

# Transportation
seed_transaction(account: visa, kind: "expense", amount: 48.00, date: this_month + 2, category: transport, note: "Gas station")
seed_transaction(account: wallet, kind: "expense", amount: 35.00, date: this_month + 6, category: transport, note: "Parking & tolls")

# Entertainment
seed_transaction(account: visa, kind: "expense", amount: 59.99, date: this_month + 8, category: entertainment, note: "Concert tickets")

# Shopping
seed_transaction(account: visa, kind: "expense", amount: 129.00, date: this_month + 5, category: shopping, note: "New running shoes")

# Health
seed_transaction(account: checking, kind: "expense", amount: 40.00, date: this_month + 6, category: health, note: "Pharmacy")

# Subscriptions
seed_transaction(account: visa, kind: "expense", amount: 15.99, date: this_month + 1, category: subscriptions, note: "Netflix")
seed_transaction(account: visa, kind: "expense", amount: 10.99, date: this_month + 1, category: subscriptions, note: "Spotify")

# Education
seed_transaction(account: checking, kind: "expense", amount: 49.99, date: this_month + 3, category: education, note: "Online course")

# Transfer: checking → savings
transfer_2_id = "seed-transfer-this-month-savings"
seed_transaction(account: checking, kind: "expense", amount: 750.00, date: this_month + 9, note: "Transfer to savings", transfer_pair_id: transfer_2_id)
seed_transaction(account: savings, kind: "income", amount: 750.00, date: this_month + 9, note: "Transfer from checking", transfer_pair_id: transfer_2_id)

# -- Budgets (current month) --

current_year = Date.current.year
current_month = Date.current.month

[
  [ groceries, 600 ],
  [ dining, 250 ],
  [ transport, 200 ],
  [ entertainment, 150 ],
  [ shopping, 300 ],
  [ utilities, 300 ],
  [ subscriptions, 50 ]
].each do |category, limit|
  Budget.find_or_create_by!(category: category, year: current_year, month: current_month) do |b|
    b.amount_limit = limit
  end
end

puts "Seeded #{Account.count} accounts, #{Category.count} categories, #{Transaction.count} transactions, #{Budget.count} budgets."
