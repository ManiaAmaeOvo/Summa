# Product Foundation

**English** | [简体中文](zh-CN/product-foundation.md)

## Product boundary

Summa is an offline, single-user ledger. Android is the first delivery platform.
No login, backend server, or network permission is required for core features.

The current product includes transaction entry and editing, hierarchical
categories, assets and liabilities, daily through yearly summaries, basic
charts, strict JSON import with editable preview, transaction export, complete
backup and restore, and local backup snapshots.

## Accounting model

Summa must not equate every cash inflow with earned income or every debt payment
with a new expense.

### Transaction types

A transaction describes one economic event:

- `expense`: consumption or loss, such as food or transport.
- `income`: an increase in net assets with an explicit source category.
- `borrowing`: increases a liability and destination personal asset by the same
  amount; it is not income and does not change liquid net worth.
- `repayment`: decreases a personal asset and target liability by the same
  amount; it is not an expense and does not change liquid net worth.
- `transfer`: moves value between two different personal asset accounts and
  affects neither income nor expense.

Income categories include earned income, family support, gifts, purchase
remainder, reimbursement, refunds, investment returns, and other sources. They
are reporting dimensions rather than separate transaction mechanics.

### Accounts and liabilities

An account represents where value is held or owed. Stable accounting kinds keep
custom names from changing balance formulas:

- cash
- bank account
- payment wallet
- credit line or personal payable
- entrusted, shared, or authorized funds

Users may add any unique account name under one of those kinds. Default personal
accounts are Cash, Bank Account, Alipay, and WeChat Pay. Default liability
accounts are Huabei, JD Baitiao, Douyin Monthly Pay, and Meituan Monthly Pay.
Family Card is entrusted or authorized funding.

Personal receivables have the opposite balance direction from liabilities and
remain a future dedicated model instead of being misclassified as debt.

Buying food with Huabei records an expense paid through a credit-line account,
increasing the liability. Paying Huabei later is repayment from a bank or wallet
account and must not duplicate the original expense.

Money received for a specific purchase can enter an entrusted-funds account.
Purchases reduce that account. A remainder can stay entrusted or be explicitly
reclassified as family support or a gift when it becomes the user's own money.

Installments are a liability account plus future installment metadata. The
purchase is recognized once; principal payments reduce the liability, while
fees and interest are separate expenses.

### Categories

Expense and income categories have two user-facing levels:

```text
Primary category → Secondary category
```

Every categorized transaction selects a secondary category, and its primary
category is derived. Each primary category has an `Other` fallback. The global
`Other → Uncategorized` path remains the final fallback when the primary
category is also unknown. `Other` stays last at both levels, so custom entries
are always inserted above the fallback.

Accounts answer “where did value move?” Categories answer “what was the economic
event for?” The two dimensions remain independent.

### Balance summaries

The mobile overview keeps four totals separate:

- Personal liquid assets: cash, bank accounts, and wallets owned by the user.
- Entrusted or authorized funds: spendable funds not counted as personal assets.
- Outstanding liabilities: positive amounts currently owed.
- Liquid net worth: personal liquid assets minus outstanding liabilities.

Fixed assets are excluded from the daily balance. A future non-liquid asset group
requires explicit valuation rules.

The dashboard prioritizes spending this month, spending this week, cumulative
recorded spending, and liquid net worth. Detailed groups remain under Accounts.

### Correction and removal

Editing replaces type, amount, time, category, accounts, and note as one
operation. All affected balances are derived again. Deleting marks a transaction
as deleted; it stops affecting lists, reports, and balances without erasing its
historical row.

Archiving an account or category prevents new use while preserving historical
resolution. Restoring defaults reactivates stable default entities without
resetting balances, custom entities, or transaction links.

Soft deletion protects integrity and does not require a visible recycle bin.
Active queries exclude deleted rows, so memory use does not grow with them; only
the SQLite file grows slowly. Compaction can be considered after real-world use
establishes an appropriate retention policy.

### Balance safety

Personal assets and entrusted funds cannot be spent below zero. Repayment cannot
exceed either the source balance or target liability. Income posted to a
liability reduces it and cannot cross zero. Repository-level atomic enforcement
ensures future JSON, OCR, and model-assisted inputs cannot bypass the rules.

When editing, validation excludes the old record before testing the replacement.

## Money and time

- Store money as integer minor units with an ISO 4217 currency code.
- Never use binary floating point for persisted amounts.
- Store timestamps as instants and retain the entry timezone offset.
- Give every persistent entity a stable ID and created/updated timestamps.
- Prefer archival or audit-preserving deletion for financial data.

## Language and naming

Fixed UI copy is available in English and Simplified Chinese. The language can
follow Android or be selected explicitly, and the preference is independent of
the financial database and backups.

Default account and category IDs are language-neutral. If a stored label still
matches a known default alias, the UI renders it in the active language. Once a
user supplies a custom name, it remains unchanged. Notes and all other
user-authored content are never translated automatically.

JSON protocol keys and enum values remain English in every locale. Untouched
defaults can be referenced by either English or Chinese labels to make generated
imports portable across language settings.

## Structured import contract

JSON is the canonical transaction interchange format and includes a
`schema_version`. Import follows: parse, validate, display a readable preview,
confirm, and commit atomically. OCR and language models may produce the JSON but
never write directly to the database.

CSV and Markdown are analysis formats, not lossless backups. Versioned complete
JSON is the recovery format.

The first schema accepts a single transaction, an array, or a canonical
envelope. Amounts are decimal strings, timestamps use ISO 8601, and category
paths are `Primary/Secondary`. Unknown accounts may be created atomically using
an explicit or inferred accounting kind. Unknown categories are rejected.

```json
{
  "schema_version": 1,
  "transactions": [
    {
      "type": "expense",
      "amount": "28.50",
      "occurred_at": "2026-09-09T12:30:00+08:00",
      "category": "Food/Lunch",
      "account": "Alipay",
      "account_kind": "wallet",
      "note": "Lunch"
    }
  ]
}
```

The importer is all-or-nothing. Rows can be edited or removed in preview, and
balance rules run again during the final database transaction. A failed batch
leaves neither transactions nor orphaned accounts. When an unknown asset account
imports earlier spending, its opening balance is set to the minimum required to
keep the imported sequence valid.

## Reports and exports

Daily, weekly, monthly, and yearly reports are computed views over source
transactions. They include income and expense balance, borrowing and repayment
totals, category pie charts, and expense/liability trends with approximate date
and amount axes.

Exports can cover the current week, month, year, all records, or a custom range
in JSON, CSV, or Markdown. Human-readable output follows the active language;
JSON structure remains stable. Reports are not duplicated archive rows.

## Complete backup and restore

A complete backup contains all accounts, opening balances, categories,
transactions, stable IDs, archive flags, and soft-deletion flags. Replace restore
recreates the snapshot exactly. Merge updates matching stable IDs while
preserving local-only rows. Both execute inside a database transaction and are
protected by the automatic snapshot guard.

Automatic and manual local snapshots are separate. Once per app launch, the
first successful ledger mutation preserves the state immediately before it;
failed validation removes the tentative snapshot. Automatic snapshots retain
the newest five. Manual snapshots do not rotate and can be renamed, deleted,
merged, or restored.

Both groups live in private app documents and are removed by uninstall or
factory reset. External export remains the durable off-device option.

Reset transactions and accounts clears transactions and custom accounts and
restores zero-balance defaults while keeping categories and backups. Factory
reset also restores default categories and removes every in-app snapshot. Both
require explicit destructive confirmation.
