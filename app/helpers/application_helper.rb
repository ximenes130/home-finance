module ApplicationHelper
  ACCOUNT_TYPE_BADGES = {
    "cash" => "bg-emerald-50 text-emerald-700",
    "checking" => "bg-blue-50 text-blue-700",
    "credit_card" => "bg-amber-50 text-amber-700",
    "savings" => "bg-indigo-50 text-indigo-700"
  }.freeze

  ACCOUNT_TYPE_LABELS = {
    "cash" => "Cash",
    "checking" => "Checking",
    "credit_card" => "Credit Card",
    "savings" => "Savings"
  }.freeze

  CATEGORY_KIND_BADGES = {
    "income" => "bg-emerald-50 text-emerald-700",
    "expense" => "bg-rose-50 text-rose-700"
  }.freeze

  CATEGORY_KIND_LABELS = {
    "income" => "Income",
    "expense" => "Expense"
  }.freeze

  TRANSACTION_KIND_BADGES = {
    "income" => "bg-emerald-50 text-emerald-700",
    "expense" => "bg-rose-50 text-rose-700",
    "transfer" => "bg-blue-50 text-blue-700"
  }.freeze

  TRANSACTION_KIND_LABELS = {
    "income" => "Income",
    "expense" => "Expense",
    "transfer" => "Transfer"
  }.freeze

  def format_currency(amount)
    number_to_currency(amount || 0)
  end

  def account_type_badge(type)
    label = ACCOUNT_TYPE_LABELS.fetch(type, type.humanize)
    classes = ACCOUNT_TYPE_BADGES.fetch(type, "bg-slate-100 text-slate-600")
    tag.span label, class: "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium #{classes}"
  end

  def category_kind_badge(kind)
    label = CATEGORY_KIND_LABELS.fetch(kind, kind.humanize)
    classes = CATEGORY_KIND_BADGES.fetch(kind, "bg-slate-100 text-slate-600")
    tag.span label, class: "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium #{classes}"
  end

  def transaction_kind_badge(transaction)
    display_kind = transaction.transfer_pair_id.present? ? "transfer" : transaction.kind
    label = TRANSACTION_KIND_LABELS.fetch(display_kind, display_kind.humanize)
    classes = TRANSACTION_KIND_BADGES.fetch(display_kind, "bg-slate-100 text-slate-600")
    tag.span label, class: "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium #{classes}"
  end

  def format_transaction_amount(transaction)
    if transaction.transfer_pair_id.present?
      tag.span format_currency(transaction.amount), class: "text-blue-600"
    elsif transaction.kind == "income"
      tag.span "+#{format_currency(transaction.amount)}", class: "text-emerald-600"
    else
      tag.span "-#{format_currency(transaction.amount)}", class: "text-rose-600"
    end
  end

  def format_transaction_date(date)
    date.strftime("%b %d, %Y")
  end

  def budget_month_label(year, month)
    Date.new(year, month, 1).strftime("%B %Y")
  end

  def prev_month_path(year, month)
    date = Date.new(year, month, 1) - 1.month
    budgets_path(year: date.year, month: date.month)
  end

  def next_month_path(year, month)
    date = Date.new(year, month, 1) + 1.month
    budgets_path(year: date.year, month: date.month)
  end

  def budget_progress_color(percent)
    if percent >= 100
      "bg-red-500"
    elsif percent >= 80
      "bg-amber-500"
    else
      "bg-emerald-500"
    end
  end

  def budget_percent_color(percent)
    if percent >= 100
      "text-red-600 font-semibold"
    elsif percent >= 80
      "text-amber-600 font-medium"
    else
      "text-emerald-600 font-medium"
    end
  end

  IMPORT_STATUS_BADGES = {
    "pending" => "bg-slate-100 text-slate-600",
    "completed" => "bg-emerald-50 text-emerald-700",
    "failed" => "bg-rose-50 text-rose-700"
  }.freeze

  IMPORT_STATUS_LABELS = {
    "pending" => "Pending",
    "completed" => "Completed",
    "failed" => "Failed"
  }.freeze

  def import_status_badge(status)
    label = IMPORT_STATUS_LABELS.fetch(status, status.humanize)
    classes = IMPORT_STATUS_BADGES.fetch(status, "bg-slate-100 text-slate-600")
    tag.span label, class: "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium #{classes}"
  end

  def nav_link_to(label, path, icon: nil)
    active = current_page?(path)
    link_classes = if active
      "flex items-center px-3 py-2 text-sm font-medium rounded-md bg-indigo-50 text-indigo-700"
    else
      "flex items-center px-3 py-2 text-sm font-medium rounded-md text-slate-700 hover:bg-slate-50 hover:text-slate-900"
    end
    icon_classes = active ? "mr-3 h-5 w-5 text-indigo-500" : "mr-3 h-5 w-5 text-slate-400"

    link_to path, class: link_classes, aria: (active ? { current: "page" } : {}) do
      safe_join([ nav_icon(icon, icon_classes), label ])
    end
  end

  private
    def nav_icon(icon, classes)
      case icon
      when :home
        tag.svg(class: classes, fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor") do
          tag.path(d: "M2.25 12l8.954-8.955a1.126 1.126 0 011.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25", stroke_linecap: "round", stroke_linejoin: "round")
        end
      when :banknotes
        tag.svg(class: classes, fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor") do
          tag.path(d: "M2.25 18.75a60.07 60.07 0 0115.797 2.101c.727.198 1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 013 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25 6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621 0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125 1.125h-.375m1.5-1.5H21a.75.75 0 00-.75.75v.75m0 0H3.75m0 0h-.375a1.125 1.125 0 01-1.125-1.125V15m1.5 1.5v-.75A.75.75 0 003 15h-.75M15 10.5a3 3 0 11-6 0 3 3 0 016 0zm3 0h.008v.008H18V10.5zm-12 0h.008v.008H6V10.5z", stroke_linecap: "round", stroke_linejoin: "round")
        end
      when :building_library
        tag.svg(class: classes, fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor") do
          tag.path(d: "M12 21v-8.25M15.75 21v-8.25M8.25 21v-8.25M3 9l9-6 9 6m-1.5 12V10.332A48.36 48.36 0 0012 9.75c-2.551 0-5.056.2-7.5.582V21M3 21h18M12 6.75h.008v.008H12V6.75z", stroke_linecap: "round", stroke_linejoin: "round")
        end
      when :tag
        tag.svg(class: classes, fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor") do
          tag.path(d: "M9.568 3H5.25A2.25 2.25 0 003 5.25v4.318c0 .597.237 1.17.659 1.591l9.581 9.581c.699.699 1.78.872 2.607.33a18.095 18.095 0 005.223-5.223c.542-.827.369-1.908-.33-2.607L11.16 3.66A2.25 2.25 0 009.568 3z", stroke_linecap: "round", stroke_linejoin: "round") +
          tag.path(d: "M6 6h.008v.008H6V6z", stroke_linecap: "round", stroke_linejoin: "round")
        end
      when :chart_bar
        tag.svg(class: classes, fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor") do
          tag.path(d: "M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 013 19.875v-6.75zM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V8.625zM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V4.125z", stroke_linecap: "round", stroke_linejoin: "round")
        end
      when :arrow_up_tray
        tag.svg(class: classes, fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor") do
          tag.path(d: "M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5m-13.5-9L12 3m0 0l4.5 4.5M12 3v13.5", stroke_linecap: "round", stroke_linejoin: "round")
        end
      when :arrow_down_tray
        tag.svg(class: classes, fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor") do
          tag.path(d: "M3 16.5v2.25A2.25 2.25 0 005.25 21h13.5A2.25 2.25 0 0021 18.75V16.5M16.5 12L12 16.5m0 0L7.5 12M12 16.5V3", stroke_linecap: "round", stroke_linejoin: "round")
        end
      else
        "".html_safe
      end
    end
end
