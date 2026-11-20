# Product Foundation

**English** | [简体中文](zh-CN/product-foundation.md)

## Product boundary

Summa is an offline, single-user ledger built for Android. Data stays on the
device until the user chooses to export or share it. Actual transactions,
financial plans, and forecasts have separate lifecycles.

## Transactions, accounts, and funding

- A transaction describes an economic event. Posted records affect the ledger
  through balanced postings in each currency. Pending records await confirmation.
- Accounts have stable accounting kinds, including cash, bank, wallet, savings,
  prepaid assets, entrusted funds, credit lines, personal payables, and
  receivables. Direct family funding has its own attribution.
- Categories describe what money was spent on or where income came from.
  Funding distinguishes personal, direct family, and entrusted payments.
  Reports track gross spending, personal spending, and personal cash flow separately.
- Borrowing increases both cash and debt. Lending or advancing cash converts
  it into receivable principal. Repayment, principal collection, and reimbursement
  move principal. Fees and interest are reported as expenses. A shared expense
  can include both personal consumption and a receivable for someone else's share.
- Transfers keep both settlement amounts. Foreign purchase prices and
  historical exchange rates remain separate from current net worth valuation.
- Refunds and reversals link to the original transaction. Reconciliation and
  calibration can record explicit balance adjustments.

## Budgets, authorized limits, and forecasts

Spending budgets may target total spending, personal spending, a category, an
account, or a funding source. A resettable allowance refreshes an entrusted
account's authorized spending each cycle. Posted card legs use the allowance.
Unused allowance expires, and a reset creates no income, cash flow, or change
in net worth.

Recurring plans, subscriptions, and debt and receivable contracts record future
obligations. Forecasts use these plans, balances, and posted entries to project
cash by currency. Plans require confirmation or a link to an actual transaction.
Savings goals allocate existing funds.

## Import, export, and recovery

- Structured JSON import supports editing and preview before an atomic commit.
  Generic CSV and WeChat Pay or Alipay statement import also supports matching,
  deduplication, category rules, manual review, and batch undo.
- Financial reports use the selected period, currency, and filters. Exports
  are available in JSON, CSV, XLSX, and Markdown.
- Full JSON backups preserve stable IDs, postings, statement sources,
  reconciliation, valuation, and plans. Replace and merge use transactions.

See the [User Guide](../USER_GUIDE.md), [financial metrics](v2/FINANCIAL_METRICS.md),
and [implementation record](v2/PROGRESS.md) for usage and acceptance details.
