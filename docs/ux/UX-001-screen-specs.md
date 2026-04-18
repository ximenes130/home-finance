# UX-001: MVP Screen Specifications — Home Finance

**Status**: Draft
**Date**: 2026-04-18
**Product area**: All MVP screens
**UX Goal**: After reviewing these specs, a Rails developer can build every view in the MVP without follow-up design questions.

---

## Table of Contents

1. [Global Layout & Navigation](#1-global-layout--navigation)
2. [Dashboard Screen](#2-dashboard-screen)
3. [Accounts Screens](#3-accounts-screens)
4. [Categories Screens](#4-categories-screens)
5. [Transactions Screens](#5-transactions-screens)
6. [Budgets Screens](#6-budgets-screens)
7. [CSV Import Screens](#7-csv-import-screens)
8. [CSV Export Screen](#8-csv-export-screen)
9. [Shared Components](#9-shared-components)
10. [Tailwind Design Tokens](#10-tailwind-design-tokens)

---

## Design Tokens Reference

These tokens apply to every screen. Individual sections reference them by name.

### Color Palette

| Role | Tailwind Class | Usage |
|------|---------------|-------|
| **Primary / Interactive** | `bg-indigo-600`, `text-indigo-600`, `hover:bg-indigo-700` | Buttons, links, focus rings |
| **Income / Positive** | `text-emerald-600`, `bg-emerald-50` | Income amounts, positive net, budget safe |
| **Expense / Negative** | `text-rose-600`, `bg-rose-50` | Expense amounts, negative net, budget over |
| **Transfer / Neutral** | `text-blue-600`, `bg-blue-50` | Transfer amounts, linked pairs |
| **Warning** | `text-amber-600`, `bg-amber-500` | Budget 80–100%, warnings |
| **Surface** | `bg-white` | Cards, page background |
| **Surface raised** | `bg-slate-50` | Section backgrounds, table headers |
| **Border** | `border-slate-200` | Dividers, card edges |
| **Text primary** | `text-slate-900` | Headings, amounts |
| **Text secondary** | `text-slate-500` | Labels, dates, helper text |
| **Text muted** | `text-slate-400` | Captions, placeholders |

### Typography Scale

| Element | Classes |
|---------|---------|
| Page title | `text-lg font-semibold text-slate-900` |
| Section heading | `text-sm font-medium text-slate-500 uppercase tracking-wide` |
| Amount (large) | `text-2xl font-semibold tabular-nums` |
| Amount (list) | `text-sm font-medium tabular-nums` |
| Body text | `text-sm text-slate-700` |
| Caption / date | `text-xs text-slate-500` |

### Spacing & Container

| Token | Classes |
|-------|---------|
| Page container | `max-w-5xl mx-auto px-4 sm:px-6 lg:px-8` |
| Card | `bg-white rounded-lg border border-slate-200 p-4 sm:p-6` |
| Card gap (between) | `space-y-4` or `gap-4` |
| Within-card gap | `space-y-2` |
| Touch target minimum | `min-h-[44px] min-w-[44px]` |

### Amount Formatting

- Always: currency symbol, thousands separator, two decimals — `$1,234.56`
- All amounts use `tabular-nums` for vertical alignment
- Right-aligned in tables; right-aligned on mobile cards
- Income: `text-emerald-600`, prefix with `+`
- Expense: `text-rose-600`, prefix with `-`
- Transfer: `text-blue-600`, no prefix
- Zero: `text-slate-400`

### Date Formatting

- Display: `Apr 18, 2026` (abbreviated month, day, four-digit year)
- Dashboard recent transactions: relative dates — `Today`, `Yesterday`, then `Apr 16`
- Form inputs: native `<input type="date">` (ISO format `2026-04-18`)

---

## 1. Global Layout & Navigation

### 1.1 Overview

The app shell provides persistent navigation, flash messages, and a content area. It adapts between desktop (sidebar) and mobile (top header + slide-out menu).

**Layout file**: `app/views/layouts/application.html.erb`

### 1.2 Desktop Layout (≥ 1024px)

```
┌──────────────────────────────────────────────────────┐
│  ┌──────────┐  ┌──────────────────────────────────┐  │
│  │           │  │  Page Title         [Quick Action]│  │
│  │  SIDEBAR  │  │                                  │  │
│  │           │  │  ┌──────────────────────────────┐│  │
│  │  Logo     │  │  │                              ││  │
│  │           │  │  │     Page Content              ││  │
│  │  Dashboard│  │  │                              ││  │
│  │  Transact.│  │  │                              ││  │
│  │  Accounts │  │  │                              ││  │
│  │  Categor. │  │  │                              ││  │
│  │  Budgets  │  │  │                              ││  │
│  │  Import   │  │  └──────────────────────────────┘│  │
│  │  Export   │  │                                  │  │
│  │           │  │  [Flash messages appear here]    │  │
│  └──────────┘  └──────────────────────────────────┘  │
└──────────────────────────────────────────────────────┘
```

### 1.3 Mobile Layout (< 1024px)

```
┌──────────────────────────┐
│ [☰]  Home Finance   [+]  │  ← sticky top header
├──────────────────────────┤
│                          │
│   [Flash message]        │
│                          │
│   Page Content           │
│   (full width)           │
│                          │
└──────────────────────────┘
```

Tapping `☰` opens a slide-out drawer overlay from the left with all nav items.

### 1.4 Component Structure

```
app/views/layouts/application.html.erb
  ├── <head> (meta, stylesheets, importmap)
  └── <body class="bg-slate-50 min-h-screen">
      ├── app/views/layouts/_sidebar.html.erb        (desktop sidebar)
      ├── app/views/layouts/_mobile_header.html.erb   (mobile header)
      ├── app/views/layouts/_mobile_drawer.html.erb   (slide-out nav)
      ├── app/views/layouts/_flash.html.erb           (flash messages)
      └── <main> (page content via yield)
```

### 1.5 Sidebar (Desktop)

```html
<!-- _sidebar.html.erb -->
<aside class="hidden lg:flex lg:flex-col lg:w-56 lg:fixed lg:inset-y-0
              bg-white border-r border-slate-200">
  <!-- Logo / App name -->
  <div class="flex items-center h-14 px-4 border-b border-slate-200">
    <span class="text-lg font-semibold text-slate-900">Home Finance</span>
  </div>

  <!-- Navigation -->
  <nav class="flex-1 px-2 py-4 space-y-1">
    <!-- Each nav item -->
    <a href="..." class="flex items-center px-3 py-2 text-sm font-medium
       rounded-md text-slate-700 hover:bg-slate-50 hover:text-slate-900
       [active: bg-indigo-50 text-indigo-700]">
      <!-- Optional icon (Heroicon inline SVG) -->
      <svg class="mr-3 h-5 w-5 text-slate-400 [active: text-indigo-500]">...</svg>
      Dashboard
    </a>
    <!-- Repeat for: Transactions, Accounts, Categories, Budgets, Import, Export -->
  </nav>
</aside>
```

**Navigation items (top to bottom):**

| Label | Path | Icon suggestion |
|-------|------|-----------------|
| Dashboard | `dashboard_path` | `home` |
| Transactions | `transactions_path` | `banknotes` |
| Accounts | `accounts_path` | `building-library` |
| Categories | `categories_path` | `tag` |
| Budgets | `budgets_path` | `chart-bar` |
| Import | `new_csv_import_path` | `arrow-up-tray` |
| Export | `new_csv_export_path` | `arrow-down-tray` |

**Active state**: Determined by `current_page?` or controller name match. Active item gets `bg-indigo-50 text-indigo-700` and its icon gets `text-indigo-500`.

### 1.6 Mobile Header

```html
<!-- _mobile_header.html.erb -->
<header class="lg:hidden sticky top-0 z-30 flex items-center justify-between
               h-14 px-4 bg-white border-b border-slate-200">
  <button data-action="click->mobile-nav#toggle" class="p-2 -ml-2 text-slate-500">
    <!-- Heroicon: bars-3 -->
    <svg class="h-6 w-6">...</svg>
  </button>
  <span class="text-base font-semibold text-slate-900">Home Finance</span>
  <!-- Quick action: + Add Transaction (most common action) -->
  <a href="new_transaction_path" class="p-2 -mr-2 text-indigo-600">
    <svg class="h-6 w-6">...</svg> <!-- Heroicon: plus -->
  </a>
</header>
```

### 1.7 Mobile Drawer

- **Stimulus controller**: `mobile-nav` — toggles `open` class, manages focus trap, closes on `Escape` or backdrop click
- **Overlay**: `fixed inset-0 z-40 bg-slate-900/50` backdrop
- **Drawer panel**: `fixed inset-y-0 left-0 w-64 bg-white` with same nav items as sidebar
- **Transition**: CSS transitions via Stimulus (slide-in from left, 200ms ease)

```html
<!-- _mobile_drawer.html.erb -->
<div data-controller="mobile-nav" data-mobile-nav-open-class="block"
     class="lg:hidden hidden" data-mobile-nav-target="container">
  <!-- Backdrop -->
  <div class="fixed inset-0 z-40 bg-slate-900/50"
       data-action="click->mobile-nav#close"></div>
  <!-- Panel -->
  <div class="fixed inset-y-0 left-0 z-50 w-64 bg-white border-r border-slate-200
              transform transition-transform duration-200">
    <div class="flex items-center h-14 px-4 border-b border-slate-200">
      <span class="text-lg font-semibold text-slate-900">Home Finance</span>
      <button class="ml-auto p-1 text-slate-400" data-action="click->mobile-nav#close">
        <svg class="h-5 w-5">...</svg> <!-- x-mark -->
      </button>
    </div>
    <nav class="px-2 py-4 space-y-1">
      <!-- Same nav items as sidebar -->
    </nav>
  </div>
</div>
```

### 1.8 Flash Messages

Rendered at the top of the `<main>` content area, inside the page container.

```html
<!-- _flash.html.erb -->
<% flash.each do |type, message| %>
  <div class="mb-4 rounded-md p-4
    <%= case type
        when 'notice' then 'bg-emerald-50 text-emerald-800 border border-emerald-200'
        when 'alert'  then 'bg-rose-50 text-rose-800 border border-rose-200'
        end %>">
    <div class="flex items-center">
      <p class="text-sm font-medium"><%= message %></p>
      <button class="ml-auto -mr-1 p-1 text-current opacity-50 hover:opacity-100"
              data-action="click->flash#dismiss">
        <svg class="h-4 w-4">...</svg> <!-- x-mark -->
      </button>
    </div>
  </div>
<% end %>
```

- **Stimulus controller**: `flash` — auto-dismiss after 5 seconds, or immediately on click
- **Turbo**: Flash messages render inside a Turbo Frame (`turbo_frame_tag "flash"`) so redirects after form submissions update them without full page reload

### 1.9 Main Content Area

```html
<main class="lg:pl-56 min-h-screen">
  <div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
    <!-- Flash messages -->
    <%= render "layouts/flash" %>
    <!-- Page content -->
    <%= yield %>
  </div>
</main>
```

### 1.10 Accessibility Notes

- Sidebar nav uses `<nav aria-label="Main navigation">`
- Mobile drawer manages focus: on open, focus moves to close button; on close, focus returns to hamburger button
- Active nav item has `aria-current="page"`
- Flash messages use `role="alert"` for screen reader announcement
- Skip-to-content link as first focusable element: `<a href="#main-content" class="sr-only focus:not-sr-only ...">Skip to content</a>`
- All nav items have minimum 44px touch targets on mobile

### 1.11 Turbo/Stimulus Notes

| Component | Mechanism |
|-----------|-----------|
| Mobile drawer | Stimulus `mobile-nav` controller (toggle visibility, manage focus trap) |
| Flash auto-dismiss | Stimulus `flash` controller (setTimeout + remove) |
| Active nav highlight | Server-rendered based on `controller_name` helper |
| Page navigation | Standard Turbo Drive (full-page morphing) |

---

## 2. Dashboard Screen

### 2.1 Overview

- **Route**: `GET /dashboard` → `dashboards#show` (also root path)
- **Entry point**: Default landing page, first item in navigation
- **UX goal**: After viewing the dashboard, the user knows their total balance, this month's income/expenses, budget health, and recent activity

### 2.2 Screen Anatomy

```
┌──────────────────────────────────────────────────┐
│  Dashboard                              Apr 2026 │  ← page header with current month
├──────────────────────────────────────────────────┤
│                                                  │
│  ┌───────────┐ ┌───────────┐ ┌──────────┐ ┌───────────┐
│  │ NET BAL.  │ │ INCOME    │ │ EXPENSES │ │ NET THIS  │  ← summary cards row
│  │ $12,450   │ │ $3,200    │ │ $2,180   │ │ +$1,020   │
│  └───────────┘ └───────────┘ └──────────┘ └───────────┘
│                                                  │
│  ─── Quick Actions ──────────────────────────── │
│  [+ Add Transaction]  [Import CSV]              │
│  [View Transactions]  [Manage Budgets]          │
│                                                  │
│  ┌─────────────────────┐ ┌──────────────────────┐
│  │ ACCOUNTS            │ │ BUDGET STATUS        │  ← two-column on desktop
│  │                     │ │                      │
│  │ Checking    $8,200  │ │ Food       ████░ 75% │
│  │ Savings     $4,000  │ │ Transport  ██████ 95%│
│  │ Cash          $250  │ │ Utilities  ███████110%│
│  │                     │ │                      │
│  │ [View all accounts] │ │ [View all budgets]   │
│  └─────────────────────┘ └──────────────────────┘
│                                                  │
│  ┌──────────────────────────────────────────────┐
│  │ RECENT TRANSACTIONS                          │  ← full width
│  │                                              │
│  │ Today    Grocery Store   Food     -$85.50    │
│  │ Today    Salary          Income   +$3,200    │
│  │ Yesterday Gas Station    Transport -$45.00   │
│  │ ...                                          │
│  │                                              │
│  │ [View all transactions →]                    │
│  └──────────────────────────────────────────────┘
│                                                  │
└──────────────────────────────────────────────────┘
```

### 2.3 Mobile Layout (< 640px)

```
┌──────────────────────────┐
│  Dashboard      Apr 2026 │
├──────────────────────────┤
│ ┌──────────┐┌──────────┐ │  ← 2×2 grid for summary cards
│ │ NET BAL. ││ INCOME   │ │
│ │ $12,450  ││ $3,200   │ │
│ └──────────┘└──────────┘ │
│ ┌──────────┐┌──────────┐ │
│ │ EXPENSES ││ NET THIS │ │
│ │ $2,180   ││ +$1,020  │ │
│ └──────────┘└──────────┘ │
│                          │
│ [+ Add Transaction] [Import CSV] │  ← horizontal scroll or wrap
│                          │
│ ── ACCOUNTS ──────────── │
│ Checking          $8,200 │
│ Savings           $4,000 │
│ Cash                $250 │
│ [View all →]             │
│                          │
│ ── BUDGETS ───────────── │
│ Food        ████░░ 75%   │
│ Transport   █████░ 95%   │
│ [View all →]             │
│                          │
│ ── RECENT ───────────── │
│ ┌────────────────────── │
│ │ Grocery Store  -$85.50│
│ │ Food · Checking       │
│ │ Today                 │
│ └────────────────────── │
│ [View all →]             │
└──────────────────────────┘
```

### 2.4 Summary Cards

**Partial**: `app/views/dashboards/_summary_cards.html.erb`

```html
<div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
  <!-- Repeat for each card -->
  <div class="bg-white rounded-lg border border-slate-200 p-4">
    <p class="text-xs font-medium text-slate-500 uppercase tracking-wide">Net Balance</p>
    <p class="mt-1 text-2xl font-semibold tabular-nums text-slate-900">
      $12,450.00
    </p>
  </div>
</div>
```

| Card | Label | Value source | Color |
|------|-------|-------------|-------|
| Net Balance | `NET BALANCE` | Sum of all active account balances | `text-slate-900` (positive) or `text-rose-600` (negative) |
| Income | `INCOME THIS MONTH` | `Transaction.where(kind: :income)` for current month | `text-emerald-600` |
| Expenses | `EXPENSES THIS MONTH` | `Transaction.where(kind: :expense)` for current month | `text-rose-600` |
| Net Result | `NET THIS MONTH` | Income − Expenses | `text-emerald-600` (positive), `text-rose-600` (negative), `text-slate-400` (zero) |

### 2.5 Quick Actions

**Partial**: `app/views/dashboards/_quick_actions.html.erb`

```html
<div class="flex flex-wrap gap-3">
  <a href="<%= new_transaction_path %>"
     class="inline-flex items-center gap-2 rounded-md bg-indigo-600 px-4 py-2.5
            text-sm font-medium text-white shadow-sm hover:bg-indigo-700
            focus-visible:outline focus-visible:outline-2
            focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
    <svg class="h-4 w-4">...</svg> <!-- plus icon -->
    Add Transaction
  </a>
  <a href="<%= new_csv_import_path %>"
     class="inline-flex items-center gap-2 rounded-md bg-white px-4 py-2.5
            text-sm font-medium text-slate-700 border border-slate-300
            shadow-sm hover:bg-slate-50">
    Import CSV
  </a>
  <!-- "View Transactions" and "Manage Budgets" as secondary links -->
</div>
```

**Button hierarchy:**
- **Primary** (filled indigo): "Add Transaction" — the most common action
- **Secondary** (outlined): "Import CSV"
- **Tertiary** (text links): "View Transactions", "Manage Budgets"

### 2.6 Accounts Overview

**Partial**: `app/views/dashboards/_accounts_overview.html.erb`

```html
<div class="bg-white rounded-lg border border-slate-200 p-4 sm:p-6">
  <h2 class="text-sm font-medium text-slate-500 uppercase tracking-wide">Accounts</h2>
  <ul class="mt-3 divide-y divide-slate-100">
    <li class="flex items-center justify-between py-2.5">
      <div class="flex items-center gap-3">
        <span class="inline-flex items-center rounded-full bg-slate-100 px-2.5 py-0.5
                     text-xs font-medium text-slate-600">Checking</span>
        <span class="text-sm font-medium text-slate-900">Main Account</span>
      </div>
      <span class="text-sm font-semibold tabular-nums text-slate-900">$8,200.00</span>
    </li>
    <!-- Repeat for each active account -->
  </ul>
  <a href="<%= accounts_path %>" class="mt-3 block text-sm font-medium text-indigo-600
     hover:text-indigo-700">View all accounts →</a>
</div>
```

- Each account row links to the account's transaction list: `account_path(account)` or filtered transactions
- Account type shown as a badge: `bg-slate-100 text-slate-600 rounded-full text-xs px-2.5 py-0.5`
- Negative balances (e.g., credit cards with debt) shown in `text-rose-600`

### 2.7 Budget Status

**Partial**: `app/views/dashboards/_budget_status.html.erb`

```html
<div class="bg-white rounded-lg border border-slate-200 p-4 sm:p-6">
  <h2 class="text-sm font-medium text-slate-500 uppercase tracking-wide">Budget Status</h2>
  <ul class="mt-3 space-y-3">
    <li>
      <div class="flex items-center justify-between text-sm">
        <span class="font-medium text-slate-700">Food & Drink</span>
        <span class="tabular-nums text-slate-500">$320 / $400</span>
      </div>
      <div class="mt-1.5 h-2 rounded-full bg-slate-100 overflow-hidden">
        <div class="h-full rounded-full bg-emerald-500" style="width: 80%"></div>
      </div>
    </li>
    <!-- Repeat for each budget -->
  </ul>
  <a href="<%= budgets_path %>" class="mt-3 block text-sm font-medium text-indigo-600
     hover:text-indigo-700">View all budgets →</a>
</div>
```

**Progress bar color logic:**

| Percentage | Fill class | Meaning |
|-----------|-----------|---------|
| < 80% | `bg-emerald-500` | Safe |
| 80–100% | `bg-amber-500` | Warning |
| > 100% | `bg-red-500` | Over budget |

Over-budget bars: cap visual width at 100% but show the actual percentage text (e.g., `110%`) in `text-red-600 font-medium`.

**Sort order**: percentage used descending (most at-risk first). Show top 5 budgets; link to full list.

### 2.8 Recent Transactions

**Partial**: `app/views/dashboards/_recent_transactions.html.erb`

Reuses the transaction row pattern (see Section 5). Shows the last 10 transactions.

**Desktop variant** — compact table:

```
Date         Description      Category     Account      Amount
Today        Grocery Store    Food         Checking     -$85.50
Yesterday    Salary           Income       Checking     +$3,200.00
```

**Mobile variant** — stacked cards (same component as transaction index mobile):

```
┌────────────────────────────────┐
│ Grocery Store           -$85.50│
│ Food · Checking                │
│ Today                          │
└────────────────────────────────┘
```

"View all transactions →" link at bottom.

### 2.9 Desktop Two-Column Layout

Accounts and Budget Status sit side by side on `sm:` and above:

```html
<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
  <%= render "dashboards/accounts_overview" %>
  <%= render "dashboards/budget_status" %>
</div>
```

### 2.10 Empty State (No Data)

When no accounts exist at all:

```
┌──────────────────────────────────────────────────┐
│                                                  │
│  Dashboard                              Apr 2026 │
│                                                  │
│  ┌──────────────────────────────────────────────┐│
│  │                                              ││
│  │         Welcome to Home Finance              ││
│  │                                              ││
│  │  Start by creating your first account to     ││
│  │  begin tracking your household finances.     ││
│  │                                              ││
│  │         [Create Your First Account]          ││
│  │                                              ││
│  └──────────────────────────────────────────────┘│
│                                                  │
└──────────────────────────────────────────────────┘
```

When accounts exist but no transactions:
- Summary cards show `$0.00` values
- Accounts section shows accounts with opening balances
- Budget section shows "No budgets set" empty state
- Recent transactions shows "No transactions yet. Add your first transaction or import from CSV." with two CTAs

### 2.11 Turbo/Stimulus Notes

| Component | Mechanism |
|-----------|-----------|
| Full page | Standard Turbo Drive page (no frames needed — dashboard is read-only) |
| Summary cards | Server-rendered; refresh on full page visit |
| Budget progress | Server-rendered; width via inline `style` attribute |

The dashboard is a read-only summary page — all mutations happen on other screens that redirect back with flash messages.

### 2.12 Accessibility Notes

- Summary cards: each card is a `<div>` with the label and value as visible text (not relying on color alone)
- Progress bars: include `role="progressbar"`, `aria-valuenow`, `aria-valuemin="0"`, `aria-valuemax="100"`, and `aria-label="Food & Drink budget: 80% used"`
- "View all" links are descriptive: `aria-label="View all accounts"` if link text is ambiguous
- Income/expense amounts: do not rely solely on color — the `+`/`-` prefix provides a non-color signal

---

## 3. Accounts Screens

### 3.1 Accounts Index

- **Route**: `GET /accounts` → `accounts#index`
- **UX goal**: See all accounts with balances at a glance, manage accounts

#### Desktop Layout

```
┌──────────────────────────────────────────────────────┐
│  Accounts                        [+ New Account]     │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────────────────────────────────────────┐│
│  │  Name            Type        Balance    Status   ││
│  ├──────────────────────────────────────────────────┤│
│  │  Main Checking   Checking    $8,200.00  Active   ││
│  │  Savings         Savings     $4,000.00  Active   ││
│  │  Wallet          Cash          $250.00  Active   ││
│  │  ─────────────────────────────────────────────── ││
│  │  Old Credit Card Credit Card     $0.00  Inactive ││
│  └──────────────────────────────────────────────────┘│
│                                                      │
└──────────────────────────────────────────────────────┘
```

#### Component Structure

**Page**: `app/views/accounts/index.html.erb`

```html
<div class="flex items-center justify-between">
  <h1 class="text-lg font-semibold text-slate-900">Accounts</h1>
  <a href="<%= new_account_path %>"
     class="inline-flex items-center gap-2 rounded-md bg-indigo-600 px-3 py-2
            text-sm font-medium text-white shadow-sm hover:bg-indigo-700">
    <svg class="h-4 w-4">...</svg>
    New Account
  </a>
</div>
```

**Table** (desktop, `hidden sm:table`):

| Column | Classes | Content |
|--------|---------|---------|
| Name | `text-sm font-medium text-slate-900` | Account name, links to `account_path` |
| Type | `text-xs rounded-full px-2.5 py-0.5 bg-slate-100 text-slate-600` | Humanized type badge |
| Balance | `text-sm font-semibold tabular-nums text-right` | Computed balance, colored: positive `text-slate-900`, negative `text-rose-600` |
| Status | `text-xs` | `text-emerald-600` "Active" or `text-slate-400` "Inactive" |
| Actions | — | Edit link, Deactivate/Reactivate toggle, Delete (conditional) |

**Type badges:**

| Type | Badge text | Extra styling |
|------|-----------|---------------|
| `cash` | Cash | `bg-emerald-50 text-emerald-700` |
| `checking` | Checking | `bg-blue-50 text-blue-700` |
| `credit_card` | Credit Card | `bg-amber-50 text-amber-700` |
| `savings` | Savings | `bg-indigo-50 text-indigo-700` |

**Inactive accounts**: Shown below active accounts, with `opacity-60` applied to the entire row. A thin divider separates active from inactive.

#### Mobile Layout

Each account becomes a card:

```
┌────────────────────────────────┐
│ Main Checking          $8,200  │  ← name + balance
│ [Checking]  Active             │  ← type badge + status
│                    [Edit] [...] │  ← actions
└────────────────────────────────┘
```

**Responsive**: `sm:hidden` for cards, `hidden sm:table` for table.

#### Empty State

```html
<div class="text-center py-12">
  <svg class="mx-auto h-12 w-12 text-slate-300">...</svg> <!-- building-library icon -->
  <h3 class="mt-2 text-sm font-semibold text-slate-900">No accounts yet</h3>
  <p class="mt-1 text-sm text-slate-500">Create your first account to start tracking finances.</p>
  <div class="mt-6">
    <a href="<%= new_account_path %>"
       class="inline-flex items-center gap-2 rounded-md bg-indigo-600 px-4 py-2.5
              text-sm font-medium text-white shadow-sm hover:bg-indigo-700">
      <svg class="h-4 w-4">...</svg>
      New Account
    </a>
  </div>
</div>
```

### 3.2 Account Form (New / Edit)

- **Routes**: `GET /accounts/new`, `GET /accounts/:id/edit`
- **Shared partial**: `app/views/accounts/_form.html.erb`

#### Form Layout

```
┌──────────────────────────────────────────────────┐
│  New Account  (or "Edit Account")                │
├──────────────────────────────────────────────────┤
│                                                  │
│  Name                                            │
│  ┌──────────────────────────────────────────────┐│
│  │ e.g. Main Checking                           ││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  Account Type                                    │
│  ┌──────────────────────────────────────────────┐│
│  │ ▼ Checking                                   ││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  Opening Balance                                 │
│  ┌──────────────────────────────────────────────┐│
│  │ 0.00                                         ││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  [Save Account]  [Cancel]                        │
│                                                  │
└──────────────────────────────────────────────────┘
```

#### Fields

| Field | Input type | Validation | Default | Notes |
|-------|-----------|------------|---------|-------|
| Name | `text_field` | Required, unique (case-insensitive) | — | `placeholder: "e.g. Main Checking"` |
| Account Type | `select` | Required, from `%w[cash checking credit_card savings]` | `checking` | Humanized labels in dropdown |
| Opening Balance | `number_field` | Numericality | `0.00` | `step: 0.01`, `placeholder: "0.00"` |

#### Form Styling

```html
<%= form_with(model: account, class: "space-y-6 max-w-lg") do |f| %>
  <div>
    <%= f.label :name, class: "block text-sm font-medium text-slate-700" %>
    <%= f.text_field :name,
        class: "mt-1 block w-full rounded-md border-slate-300 shadow-sm
               focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm
               #{'border-rose-300 text-rose-900' if account.errors[:name].any?}" %>
    <% if account.errors[:name].any? %>
      <p class="mt-1 text-sm text-rose-600"><%= account.errors.full_messages_for(:name).first %></p>
    <% end %>
  </div>
  <!-- Repeat pattern for other fields -->

  <div class="flex items-center gap-3">
    <%= f.submit class: "inline-flex items-center rounded-md bg-indigo-600 px-4 py-2.5
                         text-sm font-medium text-white shadow-sm hover:bg-indigo-700
                         cursor-pointer" %>
    <%= link_to "Cancel", accounts_path,
        class: "text-sm font-medium text-slate-600 hover:text-slate-800" %>
  </div>
<% end %>
```

**Error styling**: Invalid fields get `border-rose-300 text-rose-900 focus:border-rose-500 focus:ring-rose-500`. Error message appears below in `text-sm text-rose-600`.

### 3.3 Account Show

- **Route**: `GET /accounts/:id` → `accounts#show`

```
┌──────────────────────────────────────────────────────┐
│  ← Back to Accounts                                  │
│  Main Checking                          [Edit] [...]  │
│  [Checking]  Active                                   │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐       │
│  │ BALANCE    │ │ INCOME     │ │ EXPENSES   │       │
│  │ $8,200.00  │ │ $3,200.00  │ │ $1,540.00  │       │  ← this month for this account
│  └────────────┘ └────────────┘ └────────────┘       │
│                                                      │
│  ── Transactions ─────────────────────────────────── │
│  (Filtered to this account, same layout as Section 5)│
│  ...                                                 │
│                                                      │
└──────────────────────────────────────────────────────┘
```

- Displays account summary cards (balance, this month's income/expenses for this account)
- Lists transactions filtered to this account (reuses transaction list partial)
- **"..." dropdown menu** on desktop: Edit, Deactivate/Reactivate, Delete (conditional)

### 3.4 Deactivate / Reactivate

- **Routes**: `POST /accounts/:id/activation` (activate), `DELETE /accounts/:id/activation` (deactivate)
- No separate page — single button/link on the account show page or account index row
- **Deactivate**: Text link or button `"Deactivate"`, changes to `"Reactivate"` when inactive
- Uses a simple form with Turbo (submits, redirects back with flash message)
- Flash message: `"Main Checking has been deactivated"` / `"Main Checking has been reactivated"`

### 3.5 Delete Account

- Only available when `account.transactions.none?`
- If transactions exist: the delete button is hidden or disabled with a tooltip: `"Cannot delete — account has transactions. Deactivate instead."`
- **Confirmation**: `data-turbo-confirm: "Delete Main Checking? This cannot be undone."` attribute on the delete button/form
- On success: redirect to accounts index with flash `"Account deleted"`

### 3.6 Turbo/Stimulus Notes

| Interaction | Mechanism |
|-------------|-----------|
| Create/Edit form | Standard form submission → redirect |
| Activate/Deactivate | `button_to` with Turbo → redirect back with flash |
| Delete confirmation | `data-turbo-confirm` on the delete form |
| Account index | Full page render |

### 3.7 Accessibility Notes

- Table uses `<table>` with `<thead>` and `<th scope="col">` for screen readers
- Type badges include the type text (not icon-only)
- Delete button: includes `aria-label="Delete Main Checking account"` when rendered as icon
- Account balance doesn't rely on color alone — negative balances also get a `-` prefix

---

## 4. Categories Screens

### 4.1 Categories Index

- **Route**: `GET /categories` → `categories#index`
- **UX goal**: See all categories grouped by kind, manage them

#### Layout

```
┌──────────────────────────────────────────────────┐
│  Categories                    [+ New Category]   │
├──────────────────────────────────────────────────┤
│                                                  │
│  ── INCOME CATEGORIES ─────────────────────────  │
│  ┌──────────────────────────────────────────────┐│
│  │  Salary                          [Edit] [Del]││
│  │  Freelance                       [Edit] [Del]││
│  │  Investment Returns              [Edit] [Del]││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  ── EXPENSE CATEGORIES ────────────────────────  │
│  ┌──────────────────────────────────────────────┐│
│  │  Food & Drink                    [Edit] [Del]││
│  │  Transport                       [Edit] [Del]││
│  │  Utilities                       [Edit] [Del]││
│  │  Entertainment                   [Edit] [Del]││
│  └──────────────────────────────────────────────┘│
│                                                  │
└──────────────────────────────────────────────────┘
```

**Grouping**: Two sections with section headings (`text-sm font-medium text-slate-500 uppercase tracking-wide`). Each section is a card.

**Category row**:
```html
<li class="flex items-center justify-between py-2.5">
  <div class="flex items-center gap-2">
    <span class="inline-block h-2 w-2 rounded-full
      <%= category.income? ? 'bg-emerald-500' : 'bg-rose-500' %>"></span>
    <span class="text-sm font-medium text-slate-900"><%= category.name %></span>
  </div>
  <div class="flex items-center gap-2">
    <%= link_to "Edit", edit_category_path(category),
        class: "text-sm text-indigo-600 hover:text-indigo-700" %>
    <!-- Delete button (conditional) -->
  </div>
</li>
```

#### Empty State

```
No categories yet. Create categories to classify your transactions.
[+ New Category]
```

### 4.2 Category Form (New / Edit)

- **Partial**: `app/views/categories/_form.html.erb`

#### Fields

| Field | Input type | Validation | Default |
|-------|-----------|------------|---------|
| Name | `text_field` | Required, unique within kind | — |
| Kind | `select` | Required: `income`, `expense` | `expense` |

**Edit restriction**: If the category has transactions, the `kind` field is shown as read-only text with a help message: `"Kind cannot be changed because this category has transactions."`

#### Form Layout

Same pattern as Account form: `space-y-6 max-w-lg`, standard label/input/error styling.

### 4.3 Delete Category

- Delete only allowed when `category.transactions.none?`
- If transactions exist: show error message `"Cannot delete — category is used by X transactions. Reassign or delete those transactions first."`
- **Confirmation**: `data-turbo-confirm: "Delete 'Food & Drink'? Its budgets will also be removed. This cannot be undone."`
- Note: deleting a category cascades to its budgets (the confirmation message mentions this)

### 4.4 Turbo/Stimulus Notes

| Interaction | Mechanism |
|-------------|-----------|
| Create/Edit form | Standard form → redirect to index |
| Delete | `button_to` with `data-turbo-confirm` |
| Kind filter (optional) | Could use Turbo Frames to filter the list, but for MVP a full page render with both groups visible is sufficient |

### 4.5 Accessibility Notes

- Group headings use `<h2>` for structure
- Color dots next to names are decorative — the grouping under "Income" / "Expense" headings provides the semantic distinction
- Delete button includes the category name in `aria-label`

---

## 5. Transactions Screens

### 5.1 Transactions Index

- **Route**: `GET /transactions` → `transactions#index`
- **UX goal**: See all transactions with filters, identify income/expense/transfer at a glance

#### Desktop Layout

```
┌──────────────────────────────────────────────────────────────┐
│  Transactions                              [+ New] [↗ Transfer] │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ── Filters ─────────────────────────────────────           │
│  [Date from] [Date to] [Account ▼] [Category ▼] [Kind ▼]   │
│  [Apply Filters]  [Clear]                                    │
│                                                              │
│  ┌──────────────────────────────────────────────────────────┐│
│  │ Date       Description    Category     Account   Amount  ││
│  ├──────────────────────────────────────────────────────────┤│
│  │ Apr 18     Grocery Store  Food         Checking  -$85.50 ││
│  │ Apr 18     Salary         Income       Checking +$3,200  ││
│  │ Apr 17     Transfer to    [Transfer]   Checking -$500.00 ││
│  │            Savings        ↔ Savings             +$500.00 ││
│  │ Apr 16     Gas Station    Transport    Cash     -$45.00  ││
│  │ ...                                                      ││
│  └──────────────────────────────────────────────────────────┘│
│                                                              │
│  ← Previous  Page 1 of 5  Next →                            │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

#### Filters

**Partial**: `app/views/transactions/_filters.html.erb`

Rendered inside a Turbo Frame (`turbo_frame_tag "transactions"`) so that applying filters updates only the list without a full page reload.

```html
<%= form_with url: transactions_path, method: :get, data: { turbo_frame: "transactions" },
    class: "flex flex-wrap items-end gap-3" do |f| %>
  <div>
    <label class="block text-xs font-medium text-slate-500">From</label>
    <input type="date" name="from" value="<%= params[:from] %>"
           class="mt-1 rounded-md border-slate-300 text-sm shadow-sm
                  focus:border-indigo-500 focus:ring-indigo-500">
  </div>
  <div>
    <label class="block text-xs font-medium text-slate-500">To</label>
    <input type="date" name="to" value="<%= params[:to] %>"
           class="...">
  </div>
  <div>
    <label class="block text-xs font-medium text-slate-500">Account</label>
    <select name="account_id" class="...">
      <option value="">All accounts</option>
      <!-- Active accounts -->
    </select>
  </div>
  <div>
    <label class="block text-xs font-medium text-slate-500">Category</label>
    <select name="category_id" class="...">
      <option value="">All categories</option>
      <!-- Categories grouped by kind -->
    </select>
  </div>
  <div>
    <label class="block text-xs font-medium text-slate-500">Kind</label>
    <select name="kind" class="...">
      <option value="">All</option>
      <option value="income">Income</option>
      <option value="expense">Expense</option>
      <option value="transfer">Transfer</option>
    </select>
  </div>
  <div class="flex items-center gap-2">
    <button type="submit"
            class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-medium text-white
                   shadow-sm hover:bg-indigo-700">
      Apply
    </button>
    <a href="<%= transactions_path %>" class="text-sm text-slate-500 hover:text-slate-700">
      Clear
    </a>
  </div>
<% end %>
```

**Filter persistence**: Filters are query params (`?from=2026-04-01&to=2026-04-30&account_id=1`). They persist across pagination and back-button navigation.

**Mobile filters**: On small screens, filters wrap vertically. Consider an expandable "Filters" section (collapsed by default, expand on tap) using a Stimulus `toggle` controller with `<details>/<summary>` for no-JS fallback.

#### Transaction Table (Desktop)

**Partial**: `app/views/transactions/_transaction.html.erb` (used as a collection partial)

```html
<tr class="hover:bg-slate-50">
  <td class="py-3 pr-3 text-sm text-slate-500 whitespace-nowrap">
    Apr 18, 2026
  </td>
  <td class="py-3 pr-3 text-sm font-medium text-slate-900">
    Grocery Store
    <span class="block text-xs text-slate-400 truncate max-w-xs">Weekly shopping</span>
  </td>
  <td class="py-3 pr-3">
    <span class="inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium
                 bg-rose-50 text-rose-700">Expense</span>
  </td>
  <td class="py-3 pr-3 text-sm text-slate-500">Food & Drink</td>
  <td class="py-3 pr-3 text-sm text-slate-500">Checking</td>
  <td class="py-3 pl-3 text-sm font-medium tabular-nums text-right text-rose-600">
    -$85.50
  </td>
  <td class="py-3 pl-3 text-right">
    <a href="<%= edit_transaction_path(tx) %>" class="text-sm text-indigo-600 hover:text-indigo-700">Edit</a>
  </td>
</tr>
```

**Kind badges:**

| Kind | Classes |
|------|---------|
| Income | `bg-emerald-50 text-emerald-700` |
| Expense | `bg-rose-50 text-rose-700` |
| Transfer | `bg-blue-50 text-blue-700` |

**Transfer display**: When a transaction has a `transfer_pair_id`, show a small `↔` icon and the paired account name below the description in `text-xs text-blue-500`. E.g., `"Transfer to Savings"` with `"↔ Savings"` subtitle.

#### Transaction Cards (Mobile)

```html
<!-- Visible on sm:hidden -->
<div class="divide-y divide-slate-100">
  <a href="<%= edit_transaction_path(tx) %>" class="block py-3">
    <div class="flex items-center justify-between">
      <span class="text-sm font-medium text-slate-900 truncate">Grocery Store</span>
      <span class="text-sm font-semibold tabular-nums text-rose-600">-$85.50</span>
    </div>
    <div class="mt-0.5 flex items-center gap-1.5 text-xs text-slate-500">
      <span class="inline-flex items-center rounded-full px-1.5 py-0.5
                   bg-rose-50 text-rose-700 text-[10px] font-medium">Expense</span>
      <span>Food & Drink</span>
      <span>·</span>
      <span>Checking</span>
    </div>
    <div class="mt-0.5 text-xs text-slate-400">Apr 18, 2026</div>
  </a>
</div>
```

#### Pagination

Use Rails built-in pagination (or a minimal gem like `pagy`). Show `25` transactions per page.

```html
<nav class="flex items-center justify-between border-t border-slate-200 pt-4 mt-4" aria-label="Pagination">
  <a href="..." class="text-sm font-medium text-indigo-600 hover:text-indigo-700">← Previous</a>
  <span class="text-sm text-slate-500">Page 1 of 5</span>
  <a href="..." class="text-sm font-medium text-indigo-600 hover:text-indigo-700">Next →</a>
</nav>
```

#### Empty State

```
No transactions yet.
[+ Add Transaction]  or  [Import from CSV]
```

If filters are applied but no results:

```
No transactions match your filters.
[Clear filters]
```

### 5.2 New Transaction Form (Income / Expense)

- **Route**: `GET /transactions/new` → `transactions#new`
- **Partial**: `app/views/transactions/_form.html.erb`

#### Layout

```
┌──────────────────────────────────────────────────┐
│  New Transaction                                  │
├──────────────────────────────────────────────────┤
│                                                  │
│  Kind                                            │
│  ○ Income   ● Expense                            │  ← radio buttons, default: expense
│                                                  │
│  Account                                         │
│  ┌──────────────────────────────────────────────┐│
│  │ ▼ Main Checking                              ││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  Amount                                          │
│  ┌──────────────────────────────────────────────┐│
│  │ $  0.00                                      ││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  Date                                            │
│  ┌──────────────────────────────────────────────┐│
│  │ 2026-04-18                                   ││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  Category                                        │
│  ┌──────────────────────────────────────────────┐│
│  │ ▼ Food & Drink                               ││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  Note (optional)                                 │
│  ┌──────────────────────────────────────────────┐│
│  │                                              ││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  [Save Transaction]  [Cancel]                     │
│                                                  │
└──────────────────────────────────────────────────┘
```

#### Fields

| Field | Input | Validation | Default | Notes |
|-------|-------|------------|---------|-------|
| Kind | Radio buttons | Required: `income`, `expense` | `expense` | Determines category filtering |
| Account | `select` | Required | First active account | Only active accounts shown |
| Amount | `number_field` | Required, > 0 | — | `step: 0.01`, `min: 0.01`, `inputmode: "decimal"` |
| Date | `date_field` | Required | Today | Native date picker |
| Category | `select` | Optional (but encouraged) | — | Filtered by selected kind |
| Note | `text_area` | Optional | — | `rows: 2`, `placeholder: "Optional note"` |

#### Kind ↔ Category Filtering

When the user selects "Income", the category dropdown shows only income categories. When "Expense" is selected, only expense categories show.

**Implementation**: Stimulus controller `transaction-form` that:
1. Listens to `change` events on the kind radio buttons
2. Shows/hides `<option>` elements in the category `<select>` based on a `data-kind` attribute on each option
3. Resets category selection when kind changes

```html
<div data-controller="transaction-form">
  <div class="flex items-center gap-4">
    <label class="inline-flex items-center gap-2 cursor-pointer">
      <input type="radio" name="transaction[kind]" value="income"
             data-action="change->transaction-form#filterCategories"
             class="text-indigo-600 focus:ring-indigo-500">
      <span class="text-sm font-medium text-slate-700">Income</span>
    </label>
    <label class="inline-flex items-center gap-2 cursor-pointer">
      <input type="radio" name="transaction[kind]" value="expense" checked
             data-action="change->transaction-form#filterCategories"
             class="text-indigo-600 focus:ring-indigo-500">
      <span class="text-sm font-medium text-slate-700">Expense</span>
    </label>
  </div>

  <select data-transaction-form-target="category" name="transaction[category_id]" ...>
    <option value="">— Select category —</option>
    <option value="1" data-kind="income">Salary</option>
    <option value="2" data-kind="expense">Food & Drink</option>
    <!-- ... -->
  </select>
</div>
```

### 5.3 Transfer Form

- **Route**: `GET /transfers/new` → `transfers#new`
- **Partial**: `app/views/transfers/_form.html.erb`

#### Layout

```
┌──────────────────────────────────────────────────┐
│  New Transfer                                     │
├──────────────────────────────────────────────────┤
│                                                  │
│  From Account                                    │
│  ┌──────────────────────────────────────────────┐│
│  │ ▼ Main Checking                              ││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  To Account                                      │
│  ┌──────────────────────────────────────────────┐│
│  │ ▼ Savings                                    ││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  Amount                                          │
│  ┌──────────────────────────────────────────────┐│
│  │ $  500.00                                    ││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  Date                                            │
│  ┌──────────────────────────────────────────────┐│
│  │ 2026-04-18                                   ││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  Note (optional)                                 │
│  ┌──────────────────────────────────────────────┐│
│  │                                              ││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  [Save Transfer]  [Cancel]                        │
│                                                  │
└──────────────────────────────────────────────────┘
```

#### Fields

| Field | Input | Validation | Default |
|-------|-------|------------|---------|
| From Account | `select` | Required | — |
| To Account | `select` | Required, must differ from "from" | — |
| Amount | `number_field` | Required, > 0 | — |
| Date | `date_field` | Required | Today |
| Note | `text_area` | Optional | — |

**Validation**: "From" and "To" must be different accounts. If same account selected, show inline error: `"Source and destination accounts must be different."`

**Edit transfer**: Pre-fills amount, date, note. Account fields are read-only (display as text, not dropdowns). Help text: `"To change accounts, delete this transfer and create a new one."`

### 5.4 Edit Transaction

- **Route**: `GET /transactions/:id/edit` (income/expense), `GET /transfers/:id/edit` (transfer)
- Pre-filled form, same layout as New
- For transfers: links to `edit_transfer_path` instead, using the `transfer_pair_id` to load both sides

### 5.5 Delete Transaction

- **Confirmation**: `data-turbo-confirm: "Delete this transaction? This cannot be undone."`
- For transfers, the confirmation text is: `"Delete this transfer? Both sides of the transfer will be removed. This cannot be undone."`
- Accessible via an actions dropdown (`...` menu) on each transaction row, or a Delete button on the edit page

### 5.6 Turbo/Stimulus Notes

| Interaction | Mechanism |
|-------------|-----------|
| Filter transactions | Turbo Frame `"transactions"` wrapping filters + list + pagination. Form submits with `data-turbo-frame="transactions"` |
| Kind ↔ Category | Stimulus `transaction-form` controller for dynamic category filtering |
| Create/Edit form | Standard form → redirect to transactions index |
| Delete | `button_to` with `data-turbo-confirm` |
| Pagination | Links within the Turbo Frame |

### 5.7 Accessibility Notes

- Transaction table: proper `<thead>`, `<th scope="col">`, `<tbody>` structure
- Amount column: `+`/`-` prefix ensures non-color distinction
- Kind badges: text labels (not color-only)
- Filter form: all inputs have associated `<label>` elements
- Mobile cards: entire card is tappable (`<a>` wrapping), with adequate touch target size
- Radio buttons for kind: `fieldset` with `legend` for grouping

---

## 6. Budgets Screens

### 6.1 Budgets Index

- **Route**: `GET /budgets` → `budgets#index`
- **UX goal**: See all budget limits for a month, track spending progress

#### Layout

```
┌──────────────────────────────────────────────────────┐
│  Budgets                               [+ New Budget] │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────────────────────────────────────────┐│
│  │  [◄]   April 2026   [►]                         ││  ← month navigator
│  └──────────────────────────────────────────────────┘│
│                                                      │
│  ┌──────────────────────────────────────────────────┐│
│  │ Category         Spent       Limit     Status    ││
│  ├──────────────────────────────────────────────────┤│
│  │                                                  ││
│  │ Utilities       $220.00    $200.00    110%  OVER ││
│  │ ████████████████████████████████████ 🔴          ││
│  │                                        [Edit]    ││
│  │                                                  ││
│  │ Transport       $180.00    $200.00     90%       ││
│  │ █████████████████████████████████░░░ 🟡          ││
│  │                                        [Edit]    ││
│  │                                                  ││
│  │ Food & Drink    $320.00    $500.00     64%       ││
│  │ ██████████████████████░░░░░░░░░░░░░ 🟢          ││
│  │                                        [Edit]    ││
│  │                                                  ││
│  └──────────────────────────────────────────────────┘│
│                                                      │
│  ── Summary ─────────────────────────────────────── │
│  Total budgeted: $900.00                             │
│  Total spent: $720.00                                │
│  Overall: 80%                                        │
│                                                      │
└──────────────────────────────────────────────────────┘
```

#### Month Navigator

```html
<div class="flex items-center justify-center gap-4">
  <a href="<%= budgets_path(year: prev_year, month: prev_month) %>"
     class="p-2 text-slate-400 hover:text-slate-600" aria-label="Previous month">
    <svg class="h-5 w-5">...</svg> <!-- chevron-left -->
  </a>
  <h2 class="text-base font-semibold text-slate-900">
    April 2026
  </h2>
  <a href="<%= budgets_path(year: next_year, month: next_month) %>"
     class="p-2 text-slate-400 hover:text-slate-600" aria-label="Next month">
    <svg class="h-5 w-5">...</svg> <!-- chevron-right -->
  </a>
</div>
```

Default: current year/month. Navigation via query params: `?year=2026&month=4`.

#### Budget Row

Each budget rendered as a card-like row:

```html
<div class="py-4 border-b border-slate-100 last:border-0">
  <div class="flex items-start justify-between">
    <div class="flex-1">
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium text-slate-900">Food & Drink</span>
        <span class="text-sm tabular-nums text-slate-500">$320 / $500</span>
      </div>
      <!-- Progress bar -->
      <div class="mt-2 h-2.5 rounded-full bg-slate-100 overflow-hidden">
        <div class="h-full rounded-full bg-emerald-500"
             style="width: 64%"
             role="progressbar"
             aria-valuenow="64" aria-valuemin="0" aria-valuemax="100"
             aria-label="Food & Drink: 64% of budget used"></div>
      </div>
      <div class="mt-1 flex items-center justify-between text-xs">
        <span class="text-slate-400">$180.00 remaining</span>
        <span class="font-medium text-emerald-600">64%</span>
      </div>
    </div>
    <a href="<%= edit_budget_path(budget) %>"
       class="ml-4 text-sm text-indigo-600 hover:text-indigo-700">Edit</a>
  </div>
</div>
```

**Over-budget display**: When > 100%, the progress bar is full width with `bg-red-500`, and the percentage text shows in `text-red-600 font-semibold`. An additional label appears: `"Over budget by $20.00"` in `text-red-600 text-xs`.

**Sort order**: Percentage used descending (over-budget items at top).

#### Mobile Layout

Same layout works on mobile — the card structure is already single-column. Progress bars scale naturally.

#### Empty State

```
No budgets for April 2026.
Set spending limits to track your expenses against your plan.
[+ Create Budget]
```

### 6.2 Budget Form (New / Edit)

- **Routes**: `GET /budgets/new`, `GET /budgets/:id/edit`
- **Partial**: `app/views/budgets/_form.html.erb`

#### Fields

| Field | Input | Validation | Default | Notes |
|-------|-------|------------|---------|-------|
| Category | `select` | Required | — | **Only expense categories** shown. On edit: read-only |
| Year | `number_field` | Required, ≥ 2000 | Current year | On edit: read-only |
| Month | `select` (1–12) | Required, 1–12 | Current month | On edit: read-only. Display month names: "January"..."December" |
| Amount Limit | `number_field` | Required, > 0 | — | `step: 0.01`, `inputmode: "decimal"` |

**Edit mode**: Category, year, and month are displayed as read-only text (not editable inputs). Only the amount limit is changeable. Help text: `"To budget a different category or month, create a new budget."`

**Duplicate prevention**: If a budget already exists for the selected category+year+month, show validation error: `"A budget for Food & Drink in April 2026 already exists."`

#### Form Layout

```
┌──────────────────────────────────────────────────┐
│  New Budget                                       │
├──────────────────────────────────────────────────┤
│                                                  │
│  Category                                        │
│  ┌──────────────────────────────────────────────┐│
│  │ ▼ Food & Drink                               ││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  Month / Year                                    │
│  ┌──────────────────┐  ┌───────────────────────┐ │
│  │ ▼ April          │  │ 2026                  │ │  ← side by side
│  └──────────────────┘  └───────────────────────┘ │
│                                                  │
│  Spending Limit                                  │
│  ┌──────────────────────────────────────────────┐│
│  │ $  500.00                                    ││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  [Save Budget]  [Cancel]                          │
│                                                  │
└──────────────────────────────────────────────────┘
```

### 6.3 Delete Budget

- Available from the edit page or an actions dropdown on the index row
- **Confirmation**: `data-turbo-confirm: "Delete the budget for Food & Drink in April 2026? This does not affect any transactions."`
- Redirect to budgets index with flash

### 6.4 Turbo/Stimulus Notes

| Interaction | Mechanism |
|-------------|-----------|
| Month navigation | Standard links with query params (full page navigation) |
| Create/Edit form | Standard form → redirect |
| Delete | `button_to` with `data-turbo-confirm` |
| Progress bars | Server-rendered, width via inline `style` |

### 6.5 Accessibility Notes

- Month navigator: previous/next links have `aria-label="Previous month"` / `aria-label="Next month"`
- Progress bars: `role="progressbar"` with `aria-valuenow`, `aria-valuemin`, `aria-valuemax`, and descriptive `aria-label`
- Over-budget text "OVER" is not color-only — it's explicit text
- Budget status is communicated through both color and text percentage

---

## 7. CSV Import Screens

### 7.1 Overview

The CSV import flow is a multi-step wizard:
1. **Upload** — Select file and account
2. **Column Mapping** — Map CSV columns to transaction fields, preview rows
3. **Confirmation** — Review duplicates, select rows to import
4. **Result** — Summary of import outcome

Each step is a separate route, with a CsvImport record tracking state.

### 7.2 Step 1: Upload

- **Route**: `GET /csv_imports/new` → `csv_imports#new`

```
┌──────────────────────────────────────────────────┐
│  Import Transactions from CSV                     │
├──────────────────────────────────────────────────┤
│                                                  │
│  Step 1 of 3 — Upload File                       │
│  ●───○───○                                       │  ← progress indicator
│                                                  │
│  Account                                         │
│  ┌──────────────────────────────────────────────┐│
│  │ ▼ Main Checking                              ││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  CSV File                                        │
│  ┌──────────────────────────────────────────────┐│
│  │                                              ││
│  │  [Choose file]  or drag & drop               ││
│  │                                              ││
│  │  Accepted format: .csv                       ││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  [Upload & Continue]                              │
│                                                  │
└──────────────────────────────────────────────────┘
```

#### Fields

| Field | Input | Validation |
|-------|-------|------------|
| Account | `select` | Required. Only active accounts. |
| CSV File | `file_field` | Required. Accept `.csv` only. |

**File input styling**: Style the native file input with Tailwind, or use a styled dropzone. Keep it simple for MVP — a styled `<input type="file" accept=".csv">` with clear label.

**Error states**:
- No file selected: `"Please select a CSV file"`
- Invalid file type: `"Only .csv files are accepted"`
- Empty file: `"The uploaded file is empty"`
- Parse error: `"Could not parse the CSV file. Please check the format."`

**On success**: Creates a `CsvImport` record with `status: pending`, redirects to column mapping step.

### 7.3 Step 2: Column Mapping

- **Route**: `GET /csv_imports/:id/column_mapping` → `csv_imports/column_mappings#show`

```
┌──────────────────────────────────────────────────────────┐
│  Import Transactions from CSV                             │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  Step 2 of 3 — Map Columns                               │
│  ●───●───○                                               │
│                                                          │
│  Map your CSV columns to transaction fields:             │
│                                                          │
│  Date column          →  ┌──────────────────────┐        │
│                          │ ▼ Date (auto-detected)│        │
│                          └──────────────────────┘        │
│  Amount column        →  ┌──────────────────────┐        │
│                          │ ▼ Amount              │        │
│                          └──────────────────────┘        │
│  Category column      →  ┌──────────────────────┐        │
│  (optional)              │ ▼ Category            │        │
│                          └──────────────────────┘        │
│  Note / Description   →  ┌──────────────────────┐        │
│  (optional)              │ ▼ Description         │        │
│                          └──────────────────────┘        │
│                                                          │
│  ── Preview (first 5 rows) ──────────────────────────── │
│  ┌──────────────────────────────────────────────────────┐│
│  │ Date        | Amount  | Category     | Note         ││
│  ├──────────────────────────────────────────────────────┤│
│  │ 2026-04-01  | 85.50   | Groceries    | Weekly shop  ││
│  │ 2026-04-02  | 45.00   | Gas          | Highway      ││
│  │ 2026-04-03  | 120.00  | Utilities    | Electric     ││
│  │ 2026-04-05  | 35.00   | Restaurant   | Lunch        ││
│  │ 2026-04-07  | 15.00   | Coffee       | Morning      ││
│  └──────────────────────────────────────────────────────┘│
│                                                          │
│  [Confirm Mapping]  [← Back]                             │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

**Auto-detection**: The system guesses column mappings based on header names (e.g., "Date", "Amount", "Description"). Pre-fill the dropdowns with the best guesses. Each dropdown lists all CSV column headers.

**Required mappings**: Date and Amount must be mapped (highlighted if missing).

**Preview table**: Shows the first 5 rows of data as they would be interpreted with the current mapping. Uses `bg-slate-50` for the table header row.

**On submit**: `PATCH /csv_imports/:id/column_mapping` — saves the mapping and redirects to confirmation step.

### 7.4 Step 3: Confirmation & Duplicate Detection

- **Route**: `GET /csv_imports/:id/confirmation` → `csv_imports/confirmations#show`

```
┌──────────────────────────────────────────────────────────┐
│  Import Transactions from CSV                             │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  Step 3 of 3 — Review & Confirm                          │
│  ●───●───●                                               │
│                                                          │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐           │
│  │ TOTAL ROWS │ │ NEW        │ │ DUPLICATES │           │
│  │ 42         │ │ 38         │ │ 4          │           │
│  └────────────┘ └────────────┘ └────────────┘           │
│                                                          │
│  ── Potential Duplicates (4 rows) ───────────────────── │
│                                                          │
│  ⚠ These rows match existing transactions by fingerprint │
│                                                          │
│  ┌──────────────────────────────────────────────────────┐│
│  │ ☑ │ 2026-04-01 │ $85.50  │ Groceries  │ Weekly shop ││
│  │ ☐ │ 2026-04-02 │ $45.00  │ Gas        │ Highway     ││
│  │ ☐ │ 2026-04-03 │ $120.00 │ Utilities  │ Electric    ││
│  │ ☑ │ 2026-04-05 │ $35.00  │ Restaurant │ Lunch       ││
│  └──────────────────────────────────────────────────────┘│
│                                                          │
│  Duplicates are excluded by default. Check rows you      │
│  want to import anyway.                                  │
│                                                          │
│  ── Import Summary ──────────────────────────────────── │
│  38 new rows + 2 selected duplicates = 40 to import     │
│                                                          │
│  [Import 40 Transactions]  [← Back]  [Cancel Import]    │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

**Duplicate rows**:
- Highlighted with `bg-amber-50 border-l-4 border-amber-400`
- Checkbox to include/exclude each (unchecked by default)
- Tooltip or subtitle showing which existing transaction it matches

**Summary cards**: Same pattern as dashboard summary cards but smaller:
- Total Rows: `text-slate-900`
- New Rows: `text-emerald-600`
- Duplicate Rows: `text-amber-600`

**Dynamic count**: As user toggles duplicate checkboxes, the "X to import" count updates.

**Implementation**: Stimulus controller `import-confirmation` that:
1. Tracks checked/unchecked duplicate checkboxes
2. Updates the total count and button label dynamically

**Cancel Import**: Deletes the `CsvImport` record (which is still `pending`) and redirects to the import page.

**On submit**: `POST /csv_imports/:id/confirmation` — executes the import.

### 7.5 Import Result

- **Route**: `GET /csv_imports/:id` → `csv_imports#show` (after import completes)

```
┌──────────────────────────────────────────────────────┐
│  Import Complete ✓                                    │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐       │
│  │ IMPORTED   │ │ SKIPPED    │ │ TOTAL      │       │
│  │ 40         │ │ 2          │ │ 42         │       │
│  └────────────┘ └────────────┘ └────────────┘       │
│                                                      │
│  File: bank-statement-april.csv                      │
│  Account: Main Checking                              │
│  Imported at: Apr 18, 2026 14:32                     │
│                                                      │
│  [View Imported Transactions]  [Import Another File] │
│                                                      │
└──────────────────────────────────────────────────────┘
```

**Failed import**:
```
┌──────────────────────────────────────────────────────┐
│  Import Failed ✗                                      │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────────────────────────────────────────┐│
│  │  ⚠ An error occurred while importing:            ││
│  │  "Row 15: Amount is not a valid number"          ││
│  │                                                  ││
│  │  No transactions were imported.                  ││
│  └──────────────────────────────────────────────────┘│
│                                                      │
│  [Try Again]  [Back to Imports]                       │
│                                                      │
└──────────────────────────────────────────────────────┘
```

Error panel uses `bg-rose-50 border border-rose-200 text-rose-800`.

### 7.6 Import History

- **Route**: `GET /csv_imports` → `csv_imports#index`

```
┌──────────────────────────────────────────────────────────┐
│  Import History                        [+ New Import]     │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────────────────────────────────────────────┐│
│  │ Filename          Account     Date        Status     ││
│  ├──────────────────────────────────────────────────────┤│
│  │ statement-apr.csv Checking    Apr 18      ● Complete ││
│  │                               42 rows, 40 imported   ││
│  │                                                      ││
│  │ statement-mar.csv Checking    Mar 15      ● Complete ││
│  │                               38 rows, 38 imported   ││
│  │                                                      ││
│  │ old-data.csv      Savings     Mar 01      ● Failed   ││
│  │                               0 rows imported        ││
│  └──────────────────────────────────────────────────────┘│
│                                                          │
└──────────────────────────────────────────────────────────┘
```

**Status badges:**

| Status | Classes |
|--------|---------|
| Pending | `bg-slate-100 text-slate-600` |
| Completed | `bg-emerald-50 text-emerald-700` |
| Failed | `bg-rose-50 text-rose-700` |

Each row links to `csv_import_path(import)` to see details.

#### Empty State

```
No imports yet. Import your first CSV file to get started.
[+ Import CSV File]
```

### 7.7 Step Progress Indicator

Shared partial for the 3-step wizard: `app/views/csv_imports/_progress.html.erb`

```html
<nav aria-label="Import progress" class="mb-6">
  <ol class="flex items-center gap-2 text-sm">
    <li class="flex items-center gap-2">
      <span class="flex h-6 w-6 items-center justify-center rounded-full
        <%= step >= 1 ? 'bg-indigo-600 text-white' : 'bg-slate-200 text-slate-500' %>
        text-xs font-medium">1</span>
      <span class="<%= step >= 1 ? 'text-indigo-600 font-medium' : 'text-slate-500' %>">Upload</span>
    </li>
    <li class="h-px w-8 bg-slate-300" aria-hidden="true"></li>
    <li class="flex items-center gap-2">
      <span class="flex h-6 w-6 items-center justify-center rounded-full
        <%= step >= 2 ? 'bg-indigo-600 text-white' : 'bg-slate-200 text-slate-500' %>
        text-xs font-medium">2</span>
      <span class="<%= step >= 2 ? 'text-indigo-600 font-medium' : 'text-slate-500' %>">Map Columns</span>
    </li>
    <li class="h-px w-8 bg-slate-300" aria-hidden="true"></li>
    <li class="flex items-center gap-2">
      <span class="flex h-6 w-6 items-center justify-center rounded-full
        <%= step >= 3 ? 'bg-indigo-600 text-white' : 'bg-slate-200 text-slate-500' %>
        text-xs font-medium">3</span>
      <span class="<%= step >= 3 ? 'text-indigo-600 font-medium' : 'text-slate-500' %>">Review & Import</span>
    </li>
  </ol>
</nav>
```

### 7.8 Turbo/Stimulus Notes

| Interaction | Mechanism |
|-------------|-----------|
| File upload form | Standard form submission (multipart) |
| Column mapping preview | Could use Turbo Frame to update preview when mapping changes. For MVP, a full form submit + re-render is acceptable |
| Duplicate checkboxes → count update | Stimulus `import-confirmation` controller (updates total count on checkbox change) |
| Import confirmation (execute) | Standard form `POST` → redirect to show page |
| Step navigation | Standard page navigation (each step is a separate URL) |

### 7.9 Accessibility Notes

- Step progress: `<nav aria-label="Import progress">` with `<ol>` for ordered steps
- Current step indicated with `aria-current="step"` on the active `<li>`
- File input: associated `<label>` with clear "CSV File" text
- Duplicate checkboxes: each has an `aria-label` describing the row (e.g., "Include duplicate: $85.50 on 2026-04-01")
- Error messages use `role="alert"` for immediate announcement

---

## 8. CSV Export Screen

### 8.1 Overview

- **Route**: `GET /csv_exports/new` → `csv_exports#new`
- **UX goal**: Select filters and download a CSV file of transactions

### 8.2 Layout

```
┌──────────────────────────────────────────────────┐
│  Export Transactions                               │
├──────────────────────────────────────────────────┤
│                                                  │
│  Select which transactions to include in the     │
│  export. Leave filters blank to export all.       │
│                                                  │
│  Date Range                                      │
│  ┌──────────────────┐  ┌──────────────────┐     │
│  │ From: 2026-04-01 │  │ To: 2026-04-30   │     │  ← side by side
│  └──────────────────┘  └──────────────────┘     │
│                                                  │
│  Account                                         │
│  ┌──────────────────────────────────────────────┐│
│  │ ▼ All accounts                               ││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  Category                                        │
│  ┌──────────────────────────────────────────────┐│
│  │ ▼ All categories                             ││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  [Download CSV]                                   │
│                                                  │
│  Tip: The exported file will include columns for │
│  date, account, kind, category, amount, and note.│
│                                                  │
└──────────────────────────────────────────────────┘
```

### 8.3 Fields

| Field | Input | Default | Notes |
|-------|-------|---------|-------|
| From date | `date_field` | Blank (no lower bound) | Optional |
| To date | `date_field` | Blank (no upper bound) | Optional |
| Account | `select` | "All accounts" | Includes all (active + inactive) |
| Category | `select` | "All categories" | Optional filter |

### 8.4 Export Action

- **Route**: `POST /csv_exports` → `csv_exports#create`
- Returns a file download (`send_data` with `Content-Disposition: attachment`)
- Filename: `home-finance-export-2026-04-18.csv`
- CSV columns: `date, account, kind, category, amount, note`
- Amounts as plain numbers (no `$`, no `+`/`-`)
- Sorted by `transaction_date` ascending

**Empty export**: If no transactions match filters, the CSV has only headers. A flash notice confirms: `"Exported 0 transactions."`

**Success feedback**: After download starts, show a flash: `"Exported 42 transactions to CSV."`

### 8.5 Turbo/Stimulus Notes

| Interaction | Mechanism |
|-------------|-----------|
| Export form | Standard form `POST` with `data-turbo="false"` (file download requires disabling Turbo for this request) |

### 8.6 Accessibility Notes

- All filter inputs have associated labels
- "Download CSV" button is the primary action (`bg-indigo-600`)
- Explanatory text below the form helps users understand what will be exported

---

## 9. Shared Components

### 9.1 Buttons

| Variant | Classes | Usage |
|---------|---------|-------|
| **Primary** | `inline-flex items-center gap-2 rounded-md bg-indigo-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600` | Main actions: Save, Import, Export, Add |
| **Secondary** | `inline-flex items-center gap-2 rounded-md bg-white px-4 py-2.5 text-sm font-medium text-slate-700 border border-slate-300 shadow-sm hover:bg-slate-50` | Secondary actions: Cancel, Back |
| **Danger** | `inline-flex items-center gap-2 rounded-md bg-rose-600 px-4 py-2.5 text-sm font-medium text-white shadow-sm hover:bg-rose-700` | Delete, destructive actions |
| **Ghost** | `text-sm font-medium text-indigo-600 hover:text-indigo-700` | Text links: "View all →", "Edit", "Clear" |

### 9.2 Form Inputs

```html
<!-- Standard text/number/date input -->
<input class="block w-full rounded-md border-slate-300 shadow-sm
              focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm">

<!-- Select -->
<select class="block w-full rounded-md border-slate-300 shadow-sm
               focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm">

<!-- Textarea -->
<textarea class="block w-full rounded-md border-slate-300 shadow-sm
                 focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm" rows="2">

<!-- Label -->
<label class="block text-sm font-medium text-slate-700">

<!-- Error state input -->
<input class="... border-rose-300 text-rose-900 focus:border-rose-500 focus:ring-rose-500">
<p class="mt-1 text-sm text-rose-600">Error message here</p>
```

### 9.3 Badges

```html
<!-- Kind badges -->
<span class="inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium
             bg-emerald-50 text-emerald-700">Income</span>
<span class="... bg-rose-50 text-rose-700">Expense</span>
<span class="... bg-blue-50 text-blue-700">Transfer</span>

<!-- Account type badges -->
<span class="... bg-slate-100 text-slate-600">Checking</span>

<!-- Status badges -->
<span class="... bg-emerald-50 text-emerald-700">Active</span>
<span class="... bg-slate-100 text-slate-500">Inactive</span>
<span class="... bg-rose-50 text-rose-700">Failed</span>
```

### 9.4 Card Component

```html
<div class="bg-white rounded-lg border border-slate-200 p-4 sm:p-6">
  <!-- Card content -->
</div>
```

### 9.5 Section Heading

```html
<h2 class="text-sm font-medium text-slate-500 uppercase tracking-wide">Section Title</h2>
```

### 9.6 Empty State

```html
<div class="text-center py-12">
  <svg class="mx-auto h-12 w-12 text-slate-300"><!-- contextual icon --></svg>
  <h3 class="mt-2 text-sm font-semibold text-slate-900">No [items] yet</h3>
  <p class="mt-1 text-sm text-slate-500">Guidance text about what to do next.</p>
  <div class="mt-6">
    <!-- Primary CTA button -->
  </div>
</div>
```

### 9.7 Confirmation Dialog

All destructive actions use `data-turbo-confirm`:

```html
<%= button_to "Delete", transaction_path(tx),
    method: :delete,
    data: { turbo_confirm: "Delete this transaction? This cannot be undone." },
    class: "text-sm text-rose-600 hover:text-rose-700" %>
```

The browser's native confirm dialog is used for MVP. A custom Stimulus-powered modal can be added later.

### 9.8 Page Header

Standard page header with title and primary action:

```html
<div class="flex items-center justify-between mb-6">
  <h1 class="text-lg font-semibold text-slate-900">Page Title</h1>
  <!-- Optional primary action button -->
</div>
```

---

## 10. Tailwind Design Tokens

### 10.1 Tailwind Configuration Notes

The application uses Tailwind CSS via the asset pipeline (`app/assets/tailwind/application.css`). Ensure the following configuration:

- **Font**: System font stack (Tailwind default). Add `font-variant-numeric: tabular-nums` utility via custom class or Tailwind's `tabular-nums` class.
- **Colors**: Use Tailwind's default palette — `slate` for neutrals, `indigo` for primary, `emerald` for income/positive, `rose` for expense/negative, `blue` for transfers, `amber` for warnings.
- **Dark mode**: Not in MVP scope. All specs use light mode only. Color token table includes dark-mode-ready classes for future use but they are not implemented now.

### 10.2 Responsive Breakpoints

| Breakpoint | Tailwind prefix | Usage |
|-----------|----------------|-------|
| < 640px | (default/mobile) | Stacked cards, single-column layout, mobile header |
| ≥ 640px | `sm:` | Two-column grids, form fields side-by-side |
| ≥ 1024px | `lg:` | Sidebar navigation visible, wider content area |

### 10.3 Stimulus Controllers Summary

| Controller | File | Used by |
|-----------|------|---------|
| `mobile-nav` | `app/javascript/controllers/mobile_nav_controller.js` | Mobile drawer toggle |
| `flash` | `app/javascript/controllers/flash_controller.js` | Auto-dismiss flash messages |
| `transaction-form` | `app/javascript/controllers/transaction_form_controller.js` | Kind ↔ category filtering on transaction form |
| `import-confirmation` | `app/javascript/controllers/import_confirmation_controller.js` | Dynamic count update on duplicate checkboxes |

### 10.4 Partial File Structure

```
app/views/
├── layouts/
│   ├── application.html.erb
│   ├── _sidebar.html.erb
│   ├── _mobile_header.html.erb
│   ├── _mobile_drawer.html.erb
│   └── _flash.html.erb
├── dashboards/
│   ├── show.html.erb
│   ├── _summary_cards.html.erb
│   ├── _quick_actions.html.erb
│   ├── _accounts_overview.html.erb
│   ├── _budget_status.html.erb
│   └── _recent_transactions.html.erb
├── accounts/
│   ├── index.html.erb
│   ├── show.html.erb
│   ├── new.html.erb
│   ├── edit.html.erb
│   └── _form.html.erb
├── categories/
│   ├── index.html.erb
│   ├── new.html.erb
│   ├── edit.html.erb
│   └── _form.html.erb
├── transactions/
│   ├── index.html.erb
│   ├── new.html.erb
│   ├── edit.html.erb
│   ├── _form.html.erb
│   ├── _transaction.html.erb       (single row / card partial)
│   └── _filters.html.erb
├── transfers/
│   ├── new.html.erb
│   ├── edit.html.erb
│   └── _form.html.erb
├── budgets/
│   ├── index.html.erb
│   ├── new.html.erb
│   ├── edit.html.erb
│   ├── _form.html.erb
│   └── _budget.html.erb            (single row partial)
├── csv_imports/
│   ├── index.html.erb              (import history)
│   ├── new.html.erb                (step 1: upload)
│   ├── show.html.erb               (import result)
│   ├── _progress.html.erb          (step indicator)
│   ├── column_mappings/
│   │   └── show.html.erb           (step 2: mapping)
│   └── confirmations/
│       └── show.html.erb           (step 3: review)
└── csv_exports/
    └── new.html.erb                (export filters)
```

---

## Open Questions & Risks

1. **Icon library**: Specs reference Heroicons (outline style). Confirm whether to use inline SVGs, a gem (`heroicon`), or a Stimulus-based icon loader.
2. **Pagination gem**: Specs assume a simple pagination approach. Recommend `pagy` for performance and simplicity over `kaminari`/`will_paginate`.
3. **File upload**: For MVP, the standard Rails `file_field` with multipart form is sufficient. Active Storage is not needed since CSVs are processed immediately and not stored long-term.
4. **Number formatting**: Rails `number_to_currency` helper handles `$1,234.56` formatting. Ensure it's used consistently via a shared helper method.
5. **Transfer pair display**: Showing both sides of a transfer inline (on the same row) adds complexity. For MVP, showing them as two separate rows with a visual link indicator (↔ icon + paired account name) is simpler.
6. **Sidebar vs. bottom nav on mobile**: This spec uses a hamburger + slide-out drawer. An alternative is a bottom tab bar (5 items max). The drawer approach was chosen because there are 7 nav items (too many for bottom tabs). Revisit if navigation is simplified.
7. **Turbo Frame scope for transactions**: The transaction filter uses a Turbo Frame. Ensure that pagination links stay within the same frame and preserve filter params.
