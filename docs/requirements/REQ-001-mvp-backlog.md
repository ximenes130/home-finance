# MVP Backlog — Home Finance

**ID**: REQ-001
**Priority**: 🔴 High
**Updated**: 2026-04-18

---

## Overview

This document is the single source of truth for the Home Finance MVP build. It defines all epics, user stories, acceptance criteria, data rules, and route structure needed to implement the application from a fresh Rails 8.1 scaffold.

The MVP delivers: account management, transaction recording (income/expense/transfer), categories, monthly budgets, a dashboard, CSV import with duplicate detection, and CSV export.

---

## Key Data Rules

These rules apply across all epics and must never be violated.

### Account Balance Computation

Account balance is **always computed**, never stored:

```
balance = opening_balance + SUM(transactions where kind=income) - SUM(transactions where kind=expense)
```

Transactions with `kind=transfer` are stored as either income (destination) or expense (source), so transfers are already captured by the formula above.

### Transfer Pair Mechanics

A transfer between two accounts produces **two transactions** saved in a single database transaction:

| Side | Account | Kind | Amount |
|------|---------|------|--------|
| Source | From-account | expense | positive value |
| Destination | To-account | income | positive value |

Both records share the same `transfer_pair_id` (UUID). Deleting or editing one side must affect the other.

### Duplicate Detection via Fingerprints

During CSV import, each row gets a fingerprint derived from all mapped column values. Before inserting, the system checks for existing transactions on the same account with a matching fingerprint. Matches are flagged as potential duplicates for user review.

### Budget Unique Constraint

A budget is uniquely identified by `(category_id, year, month)`. Only one budget limit can exist per category per month. Budgets only apply to expense categories.

---

## Epics

### EP-01: Core Domain Models

**Description**: Create the database schema and Active Record models for all domain entities with validations, associations, and key computed methods.

---

#### Story 1.1: Account Model

**As** a household member,
**I want** the system to have a well-defined Account model,
**So that** financial accounts can be created and their balances computed from transactions.

**Acceptance Criteria**:

- [ ] `accounts` table has columns: `name` (string, required), `account_type` (string, required), `opening_balance` (decimal, default 0), `active` (boolean, default true), timestamps
- [ ] `account_type` is validated to be one of: `cash`, `checking`, `credit_card`, `savings`
- [ ] `name` is required and unique (case-insensitive)
- [ ] `opening_balance` defaults to `0` if not provided
- [ ] Account has many transactions (dependent: restrict_with_error)
- [ ] Account has a `balance` method that computes `opening_balance + SUM(income transactions) - SUM(expense transactions)`
- [ ] `balance` returns `opening_balance` when there are no transactions

**Data Validations**:
- `name`: presence, uniqueness (case-insensitive)
- `account_type`: presence, inclusion in `%w[cash checking credit_card savings]`
- `opening_balance`: numericality

**Edge Cases**:
- Attempting to destroy an account with transactions returns an error and prevents deletion
- Deactivating an account (`active: false`) keeps the account and its transactions intact but excludes it from active lists

---

#### Story 1.2: Category Model

**As** a household member,
**I want** the system to have a Category model for classifying transactions,
**So that** I can organize income and expenses by type.

**Acceptance Criteria**:

- [ ] `categories` table has columns: `name` (string, required), `kind` (string, required), timestamps
- [ ] `kind` is validated to be one of: `income`, `expense`
- [ ] `name` is required and unique scoped to `kind`
- [ ] Category has many transactions (dependent: restrict_with_error)
- [ ] Category has many budgets (dependent: destroy)

**Data Validations**:
- `name`: presence, uniqueness scoped to `kind`
- `kind`: presence, inclusion in `%w[income expense]`

**Edge Cases**:
- Cannot delete a category that has transactions — user must reassign or delete transactions first
- Deleting a category cascade-deletes its budgets

---

#### Story 1.3: Transaction Model

**As** a household member,
**I want** the system to have a Transaction model that records money movement,
**So that** all income, expenses, and transfers are tracked accurately.

**Acceptance Criteria**:

- [ ] `transactions` table has columns: `account_id` (references, required), `kind` (string, required), `amount` (decimal, required), `transaction_date` (date, required), `category_id` (references, optional), `note` (text, optional), `transfer_pair_id` (string/uuid, optional), `import_id` (references, optional), `fingerprint` (string, optional), timestamps
- [ ] `kind` is validated to be one of: `income`, `expense`, `transfer`
- [ ] `amount` is validated as a positive number (greater than 0)
- [ ] `transaction_date` is required
- [ ] Transaction belongs to account (required)
- [ ] Transaction belongs to category (optional)
- [ ] Transaction belongs to csv_import (optional, via `import_id`)
- [ ] Index on `fingerprint` for efficient duplicate lookups
- [ ] Index on `transfer_pair_id` for pairing lookups
- [ ] Index on `[account_id, transaction_date]` for filtered listing

**Data Validations**:
- `account_id`: presence
- `kind`: presence, inclusion in `%w[income expense transfer]`
- `amount`: presence, numericality greater than 0
- `transaction_date`: presence

**Edge Cases**:
- Transfer transactions always exist in pairs — creating one without the other is invalid at the application level
- Destroying a transfer transaction must destroy its pair
- Editing amount or date on one side of a transfer must update the paired transaction

---

#### Story 1.4: Budget Model

**As** a household member,
**I want** the system to have a Budget model linking categories to monthly spending limits,
**So that** I can track whether I'm staying within planned spending.

**Acceptance Criteria**:

- [ ] `budgets` table has columns: `category_id` (references, required), `year` (integer, required), `month` (integer, required), `amount_limit` (decimal, required), timestamps
- [ ] Unique composite index on `[category_id, year, month]`
- [ ] `month` is validated as integer between 1 and 12
- [ ] `year` is validated as a reasonable integer (e.g., >= 2000)
- [ ] `amount_limit` is validated as a positive number
- [ ] Budget belongs to category (required)
- [ ] Budget has a method to compute `spent` — the sum of expense transactions for the category in that year/month
- [ ] Budget has a method to compute `remaining` (`amount_limit - spent`)
- [ ] Budget has a method to compute `percentage_used` (`spent / amount_limit * 100`)

**Data Validations**:
- `category_id`: presence
- `year`: presence, numericality (integer, >= 2000)
- `month`: presence, numericality (integer, 1..12)
- `amount_limit`: presence, numericality greater than 0
- Unique constraint on `[category_id, year, month]`

**Edge Cases**:
- Budget is only meaningful for expense categories — validate that the associated category has `kind: expense`
- If no transactions exist for the budget period, `spent` is 0 and `percentage_used` is 0

---

#### Story 1.5: CsvImport Model

**As** a household member,
**I want** the system to track CSV import history,
**So that** I can review past imports and their outcomes.

**Acceptance Criteria**:

- [ ] `csv_imports` table has columns: `account_id` (references, required), `filename` (string, required), `row_count` (integer, default 0), `imported_count` (integer, default 0), `skipped_count` (integer, default 0), `status` (string, default "pending"), `imported_at` (datetime, optional), timestamps
- [ ] `status` is validated to be one of: `pending`, `completed`, `failed`
- [ ] CsvImport belongs to account (required)
- [ ] CsvImport has many transactions (dependent: nullify, foreign key: `import_id`)

**Data Validations**:
- `account_id`: presence
- `filename`: presence
- `status`: presence, inclusion in `%w[pending completed failed]`

**Edge Cases**:
- Deleting a CsvImport nullifies `import_id` on associated transactions (transactions are preserved)

---

### EP-02: Account Management

**Description**: CRUD interface for financial accounts. Users can create, view, edit, deactivate, and (when empty) delete accounts. Account balances are displayed as computed values.

---

#### Story 2.1: List Accounts

**As** a household member,
**I want** to see all my financial accounts with their current balances,
**So that** I know where my money is at a glance.

**Acceptance Criteria**:

- [ ] Accounts index page lists all accounts sorted by name
- [ ] Each row shows: name, account type (human-readable label), computed balance, active/inactive status
- [ ] Active accounts are listed before inactive accounts
- [ ] Balance is formatted as currency
- [ ] **Empty state**: When no accounts exist, the page shows a message like "No accounts yet" with a prominent "Add Account" button
- [ ] Page is responsive — table on desktop, stacked cards on mobile

---

#### Story 2.2: Create Account

**As** a household member,
**I want** to create a new financial account,
**So that** I can start tracking money in that account.

**Acceptance Criteria**:

- [ ] "New Account" form has fields: name, account type (dropdown), opening balance (numeric input, default 0)
- [ ] Given valid inputs, when the form is submitted, a new account is created and the user is redirected to the accounts list with a success flash
- [ ] Given invalid inputs (blank name, duplicate name), when the form is submitted, validation errors are shown inline
- [ ] New accounts default to `active: true`

---

#### Story 2.3: Edit Account

**As** a household member,
**I want** to edit an account's name, type, or opening balance,
**So that** I can correct mistakes or update account details.

**Acceptance Criteria**:

- [ ] Edit form is pre-filled with existing values
- [ ] Changing `opening_balance` immediately affects the computed balance (no transaction adjustment needed)
- [ ] Validation errors are shown inline on failure

---

#### Story 2.4: Deactivate / Reactivate Account

**As** a household member,
**I want** to deactivate an account I no longer use,
**So that** it stops appearing in active lists but its history is preserved.

**Acceptance Criteria**:

- [ ] An active account shows a "Deactivate" action
- [ ] An inactive account shows a "Reactivate" action
- [ ] Deactivating sets `active: false`; reactivating sets `active: true`
- [ ] Inactive accounts are excluded from dropdowns when creating transactions
- [ ] Inactive accounts remain visible in the accounts list (visually dimmed)

**Route note**: Model as a nested `resource :activation` under `accounts` (CRUD style per STYLE.md). `create` activates, `destroy` deactivates.

---

#### Story 2.5: Delete Account

**As** a household member,
**I want** to delete an account that has no transactions,
**So that** I can clean up accounts created by mistake.

**Acceptance Criteria**:

- [ ] Delete button is only visible/enabled when the account has zero transactions
- [ ] Given an account with no transactions, when the user clicks Delete and confirms, the account is removed
- [ ] Given an account with transactions, when deletion is attempted, an error message explains why it cannot be deleted
- [ ] Destructive action requires confirmation dialog

---

### EP-03: Category Management

**Description**: CRUD interface for transaction categories. Categories are typed as income or expense and are used for transaction classification and budget tracking.

---

#### Story 3.1: List Categories

**As** a household member,
**I want** to see all my categories organized by kind,
**So that** I can manage how transactions are classified.

**Acceptance Criteria**:

- [ ] Categories index page shows all categories grouped or filterable by kind (income / expense)
- [ ] Each entry shows: name, kind
- [ ] **Empty state**: "No categories yet" with a CTA to create one
- [ ] Page is responsive

---

#### Story 3.2: Create Category

**As** a household member,
**I want** to create a new category,
**So that** I can classify my transactions.

**Acceptance Criteria**:

- [ ] Form fields: name (text), kind (dropdown: income / expense)
- [ ] Given valid inputs, when submitted, category is created and user is redirected to the categories list
- [ ] Given a duplicate name within the same kind, validation error is shown
- [ ] Different kinds can have the same name (e.g., "Other" for both income and expense)

---

#### Story 3.3: Edit Category

**As** a household member,
**I want** to rename a category,
**So that** I can fix typos or improve clarity.

**Acceptance Criteria**:

- [ ] Edit form is pre-filled with current values
- [ ] `kind` can only be changed if the category has no transactions (changing kind would break existing transaction classification)
- [ ] Validation errors shown inline

---

#### Story 3.4: Delete Category

**As** a household member,
**I want** to delete a category that has no transactions,
**So that** I can remove unused categories.

**Acceptance Criteria**:

- [ ] Given a category with no transactions, when the user clicks Delete and confirms, the category and its budgets are removed
- [ ] Given a category with transactions, deletion is prevented with an error message
- [ ] Destructive action requires confirmation

---

### EP-04: Transaction Management

**Description**: Record income, expenses, and transfers. List and filter transactions. Edit and delete transactions with proper handling of transfer pairs.

---

#### Story 4.1: List Transactions

**As** a household member,
**I want** to see a list of all my transactions with filtering options,
**So that** I can review my financial activity.

**Acceptance Criteria**:

- [ ] Transactions index page shows transactions sorted by `transaction_date` descending (most recent first), then by `created_at` descending
- [ ] Each entry shows: date, account name, kind (income/expense/transfer), category name, amount, note (truncated)
- [ ] Income, expense, and transfer entries are visually distinct (color-coded badges or icons)
- [ ] Filters available: date range, account, category, kind
- [ ] Filters persist while browsing the list (query params or Turbo Frame)
- [ ] **Empty state**: "No transactions yet" with CTAs to add a transaction or import CSV
- [ ] Responsive: table on desktop, stacked cards on mobile
- [ ] Pagination when the list grows large

---

#### Story 4.2: Create Income Transaction

**As** a household member,
**I want** to record money coming in,
**So that** my account balance reflects the income.

**Acceptance Criteria**:

- [ ] Form fields: account (dropdown of active accounts), amount (numeric, required), date (date picker, defaults to today), category (dropdown filtered to income categories), note (optional text)
- [ ] `kind` is set to `income`
- [ ] Given valid inputs, when submitted, the transaction is created and the user is redirected to the transactions list with a success flash
- [ ] The related account's computed balance increases by the transaction amount
- [ ] Validation errors shown inline for missing required fields or invalid amount

---

#### Story 4.3: Create Expense Transaction

**As** a household member,
**I want** to record money going out,
**So that** my account balance reflects the expense.

**Acceptance Criteria**:

- [ ] Form fields: account (dropdown of active accounts), amount (numeric, required), date (date picker, defaults to today), category (dropdown filtered to expense categories), note (optional text)
- [ ] `kind` is set to `expense`
- [ ] Given valid inputs, when submitted, the transaction is created and the user is redirected to the transactions list
- [ ] The related account's computed balance decreases by the transaction amount
- [ ] Validation errors shown inline

---

#### Story 4.4: Create Transfer

**As** a household member,
**I want** to record a transfer between two accounts,
**So that** the money movement is tracked on both sides.

**Acceptance Criteria**:

- [ ] Transfer form fields: from-account (dropdown), to-account (dropdown), amount (numeric, required), date (date picker, defaults to today), note (optional)
- [ ] From-account and to-account must be different — validation error if same account selected
- [ ] Given valid inputs, when submitted, **two transactions** are created in a single DB transaction:
  - Expense on the from-account with `kind: transfer`
  - Income on the to-account with `kind: transfer`
  - Both share the same generated `transfer_pair_id` (UUID)
- [ ] Category is optional for transfers (transfers may not need categorization)
- [ ] From-account balance decreases by amount; to-account balance increases by amount
- [ ] The transaction list shows each side of the transfer as a separate row, with a visual indicator that it is part of a transfer

---

#### Story 4.5: Edit Transaction

**As** a household member,
**I want** to edit a transaction's details,
**So that** I can correct mistakes.

**Acceptance Criteria**:

- [ ] Edit form is pre-filled with current values
- [ ] For non-transfer transactions: account, amount, date, category, and note are editable
- [ ] For transfer transactions: editing amount or date updates both paired transactions. Changing accounts is not allowed on a transfer (user should delete and recreate)
- [ ] Validation errors shown inline

---

#### Story 4.6: Delete Transaction

**As** a household member,
**I want** to delete a transaction,
**So that** I can remove erroneous records.

**Acceptance Criteria**:

- [ ] Destructive action requires confirmation
- [ ] Deleting a non-transfer transaction removes that single record
- [ ] Deleting either side of a transfer deletes **both** paired transactions
- [ ] Account balance is immediately recomputed (automatically, since balance is derived)

---

### EP-05: Dashboard

**Description**: The home screen provides an at-a-glance financial summary: account balances, monthly income/expenses, budget status, and recent transactions with quick actions.

---

#### Story 5.1: Dashboard Summary Cards

**As** a household member,
**I want** to see top-level financial numbers on the dashboard,
**So that** I immediately know my financial position.

**Acceptance Criteria**:

- [ ] Dashboard shows four summary cards:
  - **Net Balance**: sum of all active account balances
  - **Income This Month**: sum of income transactions in the current month
  - **Expenses This Month**: sum of expense transactions in the current month
  - **Net This Month**: income minus expenses for the current month
- [ ] Negative values are visually distinct (e.g., red text)
- [ ] Cards are responsive: horizontal row on desktop, stacked on mobile
- [ ] **Empty state**: Cards show $0 values with a message guiding the user to create accounts and transactions

---

#### Story 5.2: Accounts Overview on Dashboard

**As** a household member,
**I want** to see all active accounts with balances on the dashboard,
**So that** I can quickly see where money is distributed.

**Acceptance Criteria**:

- [ ] Section lists active accounts with: name, type icon/label, computed balance
- [ ] Each account links to a filtered transaction list for that account
- [ ] **Empty state**: "No accounts yet" with link to create one

---

#### Story 5.3: Budget Status on Dashboard

**As** a household member,
**I want** to see which budgets are close to or over their limit,
**So that** I can adjust spending before it's too late.

**Acceptance Criteria**:

- [ ] Section shows budgets for the current month with: category name, amount spent, amount limit, percentage used
- [ ] Visual indicator: progress bar or similar, with escalating color (green < 80%, yellow 80-100%, red > 100%)
- [ ] Only budgets that exist for the current month are shown
- [ ] Sorted by percentage used descending (most at-risk first)
- [ ] **Empty state**: "No budgets set for this month" with link to manage budgets
- [ ] Links to the budgets page for full details

---

#### Story 5.4: Recent Transactions on Dashboard

**As** a household member,
**I want** to see the most recent transactions on the dashboard,
**So that** I can quickly review recent activity.

**Acceptance Criteria**:

- [ ] Section shows the last 10 transactions across all accounts
- [ ] Each row shows: date, account, kind badge, category, amount
- [ ] "View all transactions" link at the bottom
- [ ] **Empty state**: "No transactions yet" with links to add one or import CSV

---

#### Story 5.5: Quick Actions

**As** a household member,
**I want** quick access to common actions from the dashboard,
**So that** I can perform frequent tasks without navigating deep.

**Acceptance Criteria**:

- [ ] Dashboard shows quick action buttons/links: "Add Transaction", "Import CSV", "View Transactions", "Manage Budgets"
- [ ] Quick actions are prominent and accessible on mobile (near the top of the page)

---

### EP-06: Budget Management

**Description**: CRUD interface for monthly budgets per expense category. Users define spending limits and compare actual spending against them.

---

#### Story 6.1: List Budgets

**As** a household member,
**I want** to see all budgets for a given month,
**So that** I can review and manage my spending limits.

**Acceptance Criteria**:

- [ ] Budgets index page shows budgets filterable by year/month (defaults to current month)
- [ ] Each entry shows: category name, amount limit, amount spent, remaining, percentage used with visual indicator
- [ ] Visual indicator uses escalating color (green / yellow / red) based on percentage thresholds
- [ ] Budgets are sorted by percentage used descending
- [ ] **Empty state**: "No budgets for this month" with CTA to create one
- [ ] Navigation to switch between months (previous / next)

---

#### Story 6.2: Create Budget

**As** a household member,
**I want** to set a monthly spending limit for a category,
**So that** I can control my expenses.

**Acceptance Criteria**:

- [ ] Form fields: category (dropdown of expense categories only), year (defaults to current year), month (dropdown 1-12, defaults to current month), amount limit (numeric, required)
- [ ] Given valid inputs, when submitted, budget is created and user is redirected to the budgets list
- [ ] Given a duplicate (same category + year + month), validation error is shown
- [ ] Only expense categories appear in the dropdown

---

#### Story 6.3: Edit Budget

**As** a household member,
**I want** to adjust a budget's spending limit,
**So that** I can update my plan as circumstances change.

**Acceptance Criteria**:

- [ ] Edit form is pre-filled with current values
- [ ] Category, year, and month are read-only (to preserve the unique constraint — user should delete and recreate for a different combination)
- [ ] Amount limit is editable
- [ ] Validation errors shown inline

---

#### Story 6.4: Delete Budget

**As** a household member,
**I want** to remove a budget I no longer need,
**So that** it stops appearing in my budget overview.

**Acceptance Criteria**:

- [ ] Destructive action requires confirmation
- [ ] Deleting a budget does not affect any transactions
- [ ] User is redirected to the budgets list after deletion

---

### EP-07: CSV Import

**Description**: Import transactions from a CSV file into an account. The system parses the file, auto-detects column mapping, shows a preview, detects duplicates via fingerprints, and lets the user confirm before importing.

---

#### Story 7.1: Upload CSV File

**As** a household member,
**I want** to upload a CSV file and select a target account,
**So that** I can start importing transactions.

**Acceptance Criteria**:

- [ ] Import page has: file upload input (accepts `.csv`), account dropdown (active accounts only)
- [ ] Given a valid CSV file, when uploaded, the system parses the file and creates a CsvImport record with `status: pending`
- [ ] Given an invalid file (non-CSV, empty, unparseable), an error message is shown
- [ ] After upload, the user is taken to the column mapping step

---

#### Story 7.2: Column Mapping & Preview

**As** a household member,
**I want** the system to auto-detect CSV columns and let me adjust the mapping,
**So that** transaction fields are populated correctly.

**Acceptance Criteria**:

- [ ] System attempts automatic column mapping by matching CSV headers to known fields: date, amount, category, note/description
- [ ] User sees a mapping form: each required transaction field has a dropdown listing CSV column headers
- [ ] Preview shows the first 5 rows as they would be imported with the current mapping
- [ ] User can adjust mappings and see the preview update
- [ ] Required mappings: date column, amount column. Optional: category, note
- [ ] User confirms mapping to proceed to duplicate detection

---

#### Story 7.3: Duplicate Detection & Confirmation

**As** a household member,
**I want** the system to warn me about potential duplicate transactions before importing,
**So that** I don't accidentally import the same data twice.

**Acceptance Criteria**:

- [ ] After mapping confirmation, the system generates a fingerprint for each row based on all mapped column values
- [ ] System checks existing transactions on the target account for matching fingerprints
- [ ] Rows with matching fingerprints are flagged as "potential duplicates"
- [ ] User sees a summary: total rows, new rows, duplicate rows
- [ ] Duplicate rows are visually highlighted and can be individually included or excluded
- [ ] User can proceed to import selected rows or cancel

---

#### Story 7.4: Execute Import

**As** a household member,
**I want** to confirm and execute the CSV import,
**So that** the transactions are saved to my account.

**Acceptance Criteria**:

- [ ] Given confirmed rows, when the user clicks Import:
  - Transactions are created for each accepted row with `import_id` set to the CsvImport record and `fingerprint` set
  - CsvImport record is updated: `status: completed`, `row_count`, `imported_count`, `skipped_count`, `imported_at`
- [ ] On success, user sees an import summary with counts
- [ ] On failure (e.g., validation errors mid-import), CsvImport status is set to `failed` and user sees error details
- [ ] All imported transactions for a single import are created within a DB transaction (all-or-nothing)

---

#### Story 7.5: Import History

**As** a household member,
**I want** to review past CSV imports,
**So that** I know what was imported, when, and whether there were issues.

**Acceptance Criteria**:

- [ ] Import history page lists all CsvImport records sorted by `created_at` descending
- [ ] Each entry shows: filename, account name, date, status badge, row count, imported count, skipped count
- [ ] Status badges are color-coded: pending (gray), completed (green), failed (red)
- [ ] **Empty state**: "No imports yet" with CTA to import a file

---

### EP-08: CSV Export

**Description**: Export transactions to a downloadable CSV file with optional filters.

---

#### Story 8.1: Export Transactions to CSV

**As** a household member,
**I want** to export my transactions to a CSV file,
**So that** I have a portable backup or can analyze data in a spreadsheet.

**Acceptance Criteria**:

- [ ] Export page or action allows selecting filters: date range, account, category (all optional — default exports all transactions)
- [ ] Given selected filters, when the user clicks Export, a CSV file is generated and downloaded
- [ ] CSV includes columns: date, account name, kind, category name, amount, note
- [ ] CSV rows are sorted by `transaction_date` ascending
- [ ] Filename follows a pattern like `home-finance-export-YYYY-MM-DD.csv`
- [ ] Amounts are exported as plain numbers (no currency symbols)
- [ ] Export works for zero transactions (produces a CSV with only headers)

---

## API / Route Structure

All routes follow RESTful CRUD conventions per STYLE.md. Custom actions are modeled as nested resources.

```ruby
Rails.application.routes.draw do
  root "dashboards#show"

  resource :dashboard, only: [:show]

  resources :accounts do
    resource :activation, only: [:create, :destroy],
      controller: "accounts/activations"
  end

  resources :categories

  resources :transactions

  # Transfer is a separate resource that creates paired transactions
  resources :transfers, only: [:new, :create, :edit, :update, :destroy]

  resources :budgets

  resources :csv_imports, only: [:index, :new, :create, :show] do
    # Column mapping step
    resource :column_mapping, only: [:show, :update],
      controller: "csv_imports/column_mappings"
    # Confirmation/execution step
    resource :confirmation, only: [:show, :create],
      controller: "csv_imports/confirmations"
  end

  resources :csv_exports, only: [:new, :create]
end
```

### Route Summary

| Resource | Actions | Purpose |
|----------|---------|---------|
| `dashboard` | `show` | Main dashboard / home screen |
| `accounts` | `index`, `show`, `new`, `create`, `edit`, `update`, `destroy` | Account CRUD |
| `accounts/activations` | `create`, `destroy` | Activate / deactivate account |
| `categories` | `index`, `show`, `new`, `create`, `edit`, `update`, `destroy` | Category CRUD |
| `transactions` | `index`, `show`, `new`, `create`, `edit`, `update`, `destroy` | Transaction CRUD (income/expense) |
| `transfers` | `new`, `create`, `edit`, `update`, `destroy` | Transfer creation/editing (creates paired transactions) |
| `budgets` | `index`, `show`, `new`, `create`, `edit`, `update`, `destroy` | Budget CRUD |
| `csv_imports` | `index`, `new`, `create`, `show` | Upload CSV, view import history |
| `csv_imports/column_mappings` | `show`, `update` | Map CSV columns to transaction fields |
| `csv_imports/confirmations` | `show`, `create` | Preview duplicates and execute import |
| `csv_exports` | `new`, `create` | Configure filters and download CSV |

### Controller Nesting

```
app/controllers/
├── application_controller.rb
├── dashboards_controller.rb
├── accounts_controller.rb
├── accounts/
│   └── activations_controller.rb
├── categories_controller.rb
├── transactions_controller.rb
├── transfers_controller.rb
├── budgets_controller.rb
├── csv_imports_controller.rb
├── csv_imports/
│   ├── column_mappings_controller.rb
│   └── confirmations_controller.rb
└── csv_exports_controller.rb
```

---

## Navigation Structure

Main navigation items (persistent across all pages):

1. **Dashboard** → `dashboard_path`
2. **Transactions** → `transactions_path`
3. **Accounts** → `accounts_path`
4. **Categories** → `categories_path`
5. **Budgets** → `budgets_path`
6. **Import** → `new_csv_import_path`
7. **Export** → `new_csv_export_path`

---

## Build Order & Dependencies

```
EP-01 (Models) ─────────────────────────────────────────────────────┐
  │                                                                  │
  ├── EP-02 (Accounts) ── requires Account model                     │
  │                                                                  │
  ├── EP-03 (Categories) ── requires Category model                  │
  │     │                                                            │
  │     ├── EP-04 (Transactions) ── requires Account + Category      │
  │     │     │                                                      │
  │     │     ├── EP-05 (Dashboard) ── requires Accounts +           │
  │     │     │                        Transactions + Budgets        │
  │     │     │                                                      │
  │     │     ├── EP-07 (CSV Import) ── requires Transactions +      │
  │     │     │                         CsvImport model              │
  │     │     │                                                      │
  │     │     └── EP-08 (CSV Export) ── requires Transactions        │
  │     │                                                            │
  │     └── EP-06 (Budgets) ── requires Category + Transaction       │
  │                             (for spent calculation)              │
  └──────────────────────────────────────────────────────────────────┘
```

**Recommended implementation sequence**:

1. **EP-01** — Core Domain Models (foundation for everything)
2. **EP-02** — Account Management (first visible CRUD)
3. **EP-03** — Category Management (needed before transactions)
4. **EP-04** — Transaction Management (core feature)
5. **EP-06** — Budget Management (depends on categories + transactions for spent calc)
6. **EP-05** — Dashboard (aggregates data from all above)
7. **EP-07** — CSV Import (extends transactions with import workflow)
8. **EP-08** — CSV Export (read-only feature, lowest risk)
