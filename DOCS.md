# Home Finance

Simple household finance management for Home Assistant.

Track cash, checking, credit card, and savings accounts. Record income, expenses, and transfers.
Assign categories, define monthly budgets, and view a monthly dashboard at a glance.

## Configuration

### Option: `timezone`

The timezone used for displaying dates and times.
Use a standard IANA timezone name such as `America/New_York`, `Europe/London`, or `UTC`.

**Default:** `UTC`

### Option: `currency`

The currency code displayed alongside monetary amounts.
Examples: `USD`, `EUR`, `GBP`, `BRL`.

**Default:** `USD`

## Data Storage

All data (SQLite databases and CSV exports) is stored in the add-on's persistent `/data` directory.
Data is preserved across add-on restarts, updates, and Home Assistant reboots.

## Access

Once started, the app is accessible from the **Home Finance** entry in the Home Assistant sidebar.
