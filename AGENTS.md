# Home Finance

This file provides guidance to AI coding agents working with this repository.

## What is Home Finance?

Home Finance is a simple household finance application built as a Ruby on Rails app, designed to be packaged as a Home Assistant add-on. It focuses on recording money movement clearly and producing useful monthly views with minimal setup and a small operational footprint.

Key Features:
* **Account Management**: Track cash, checking, credit card, and savings accounts.
* **Transaction Recording**: Record income, expenses, and transfers between accounts.
* **Categories & Budgets**: Assign categories to transactions and define monthly budget limits per category.
* **Monthly Dashboard**: View current balances, monthly income/expenses, net result, and budget status at a glance.
* **CSV Import/Export**: Import transactions from CSV with automatic column mapping, duplicate detection via row fingerprints, and export transactions to CSV.
* **Home Assistant Integration**: Runs as a Docker-based Home Assistant add-on with ingress support.

See [docs/home-finance-app-plan.md](docs/home-finance-app-plan.md) for the full product plan.

## Development Commands

### Setup and Server
```bash
bin/setup              # Initial setup (installs gems, creates DB, loads schema)
bin/setup --reset      # Reset the database and seed it
bin/dev                # Start development server (default port 3000)
```

Development URL: http://localhost:3000

### Testing
```bash
bin/rails test                         # Run unit tests
bin/rails test test/path/file_test.rb  # Run single test file
bin/rails test:system                  # Run system tests (Capybara + Selenium)
bin/ci                                 # Run full CI suite (style, security, tests)

# For parallel test execution issues, use:
PARALLEL_WORKERS=1 bin/rails test
```

CI pipeline (`bin/ci`) runs:
1. Rubocop (style)
2. Bundler audit (gem security)
3. Importmap audit
4. Brakeman (security scan)
5. Application tests
6. Seeds test

### Database
```bash
bin/rails db:migrate          # Run migrations
bin/rails db:reset            # Drop, create, and load schema
bin/rails db:seed             # Seed data
```

### Other Utilities
```bash
bin/jobs                     # Manage Solid Queue jobs
bin/kamal deploy             # Deploy (uses config/deploy.yml)
```

## Deploy

Default branch: `main`
Pre-deploy: `bin/kamal setup` for initial setup.
Deploy: `bin/kamal deploy` (Uses config/deploy.yml)
We use Kamal for deployment. Target is also Docker-based Home Assistant add-on packaging.

## Architecture Overview

### Tech Stack

* **Ruby on Rails 8.1** with SQLite (single database in dev/test, multi-database in production)
* **Hotwire** (Turbo + Stimulus) for lightweight interactivity
* **Tailwind CSS** for styling
* **Propshaft** for asset pipeline
* **Solid Queue** for background jobs (database-backed, no Redis)
* **Solid Cache** for caching
* **Solid Cable** for ActionCable

### Core Domain Models

**Account** → Financial accounts
- name, type (cash, checking, credit_card, savings)
- opening_balance, active (boolean)
- Balance is always computed from `opening_balance + SUM(income) - SUM(expenses)`, never stored directly

**Transaction** → Money movement records
- account_id, kind (income, expense, transfer), amount (always positive; kind determines direction)
- transaction_date, category_id, note (optional)
- transfer_pair_id (optional, shared UUID linking two sides of a transfer)
- import_id (optional, references CsvImport), fingerprint (optional, for duplicate detection)

**Category** → Transaction classification
- name, kind (income or expense)

**Budget** → Monthly spending limits
- category_id, year, month, amount_limit
- Unique constraint on (category_id, year, month)

**CsvImport** → Import history tracking
- account_id, filename, row_count, imported_count, skipped_count
- status (pending, completed, failed), imported_at

### Key Data Rules

- Account balance = `opening_balance + SUM(income) - SUM(expenses)` — always computed, never stored.
- Deleting an account is only allowed when it has no transactions. Accounts can be deactivated instead.
- A transfer produces two transactions with the same `transfer_pair_id`: one expense on the source, one income on the destination.

### Background Jobs (Solid Queue)

Database-backed job queue (no Redis). Jobs run in Puma via `SOLID_QUEUE_IN_PUMA=true`.

### Home Assistant Add-on

The app is designed to be packaged as a Docker-based Home Assistant add-on:
- Persistent storage mounted at `/data` for SQLite and exports
- Accessible through Home Assistant ingress (dynamic base path via `RAILS_RELATIVE_URL_ROOT`)
- Minimal configuration: timezone, currency

## Coding Style

@STYLE.md
