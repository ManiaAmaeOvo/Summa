# Product foundation

## Product boundary

Summa is an offline, single-user ledger. Android is the first delivery
platform. No login, server, or network permission is required for core features.

The first useful version includes transaction entry and editing, hierarchical
categories, accounts and liabilities, daily/weekly/monthly summaries, basic
charts, strict JSON import with preview, and JSON/CSV/database export.

## Accounting model

Summa must not equate every cash inflow with earned income, or every debt
repayment with a new expense.

### Transactions

A transaction describes an economic event:

- `expense`: consumption or loss, such as food or transport.
- `income`: an increase in the user's net assets, with an explicit source kind.
- `borrowing`: increases a liability and a destination personal asset by the
  same amount; it is not income and does not change liquid net assets.
- `repayment`: decreases a personal asset and a target liability by the same
  amount; it is not an expense and does not change liquid net assets.

A general account-to-account `transfer` and explicit balance-adjustment audit
records remain later extensions.

Income source kinds initially include earned income, family support, gift,
reimbursement, refund, investment return, and other. They are reporting
dimensions, not separate transaction mechanics.

### Accounts and liabilities

An account represents where value is held or owed. Version 1 keeps five stable
accounting kinds so custom names never make balance formulas ambiguous:

- cash
- bank account
- payment wallet
- credit line (for example Huabei or Baitiao)
- entrusted funds or shared/authorized funds

Users can add any account name under one of these kinds. The initial personal
accounts are Cash, Bank Card, Alipay, and WeChat; the initial liability accounts
are Huabei, Baitiao, Douyin Monthly Pay, and Meituan Monthly Pay. Family Card is
seeded separately as entrusted/authorized funds. Personal payables can initially
use named liability accounts. Receivables need the opposite balance direction,
so they remain a later dedicated model rather than being misclassified as debt.

Buying food with Huabei records an expense paid from a credit-line account and
therefore increases that account's liability. Paying Huabei later is a repayment
from a bank or wallet account to the credit-line account, not another expense.

Money received for a specific purchase may be recorded into an entrusted-funds
account. Purchases reduce that account. Any remainder can stay attributed to the
original entrusted funds, or be reclassified explicitly as family support/gift
when the user decides it has become their money. This prevents all family money
from being reported as earned income.

Installments are represented by a liability account plus installment metadata.
The purchase is recognized once; principal repayments are transfers. Fees and
interest are separate expenses.

### Categories

Expense and income categories have exactly two user-facing levels in version 1:

```text
parent category -> child category
```

Every categorized transaction selects a child category; the parent is derived
from it. A built-in `Uncategorized` child remains available so entry is never
blocked. Categories can be archived but are not hard-deleted while referenced.

Accounts answer “where did the money move?” Categories answer “what was this
economic event for?” They must remain independent.

Every common expense parent category includes an `Other` child. The global
`Other -> Uncategorized` path remains the final fallback when even the parent
category is unknown.

### Balance summaries

The mobile balance overview keeps four totals separate:

- Personal liquid assets: cash, bank accounts, and wallets owned by the user.
- Entrusted or authorized funds: family cards and purchase money that can be
  spent but is not counted as personal property.
- Outstanding liabilities: positive amounts currently owed on credit lines and
  personal payables.
- Liquid net assets: personal liquid assets minus outstanding liabilities.

Fixed assets are excluded from the version 1 daily balance. They may later be
introduced as a separate non-liquid asset group with explicit valuation rules.

The home dashboard prioritizes four immediately useful figures: spending this
month, spending this week, cumulative recorded spending, and liquid net assets.
Detailed account-group totals remain on the Accounts screen.

### Correction and removal rules

Editing a record replaces its type, amount, date, category, involved accounts,
and note as one operation; all affected balances are derived again from the
resulting ledger. Deleting a record marks it as deleted rather than erasing the
stored row, and deleted records no longer affect lists, reports, or balances.

Removing an account deactivates it. Historical entries continue to resolve its
name, while new entries cannot select it. Restoring built-in accounts only
reactivates their stable records and never resets balances or transaction links.

Soft deletion is an integrity mechanism and does not require a visible recycle
bin. Active queries exclude deleted rows, so they do not accumulate in memory;
only the local SQLite file grows slowly. A future maintenance action may purge
old deleted rows after a verified backup and compact the database, but automatic
purging is intentionally avoided while audit and restore requirements are still
being decided.

### Balance safety rules

Personal assets and entrusted funds cannot be spent below zero. A repayment
cannot exceed either the selected payment account balance or the outstanding
target liability. Income posted directly to a liability is treated as a debt
reduction and likewise cannot reduce that liability below zero. These rules are
enforced atomically in the repository rather than only in the UI, so future JSON,
OCR, and language-model imports cannot bypass them. When editing, validation
first excludes the old version of that record and then checks the replacement.

## Money and time rules

- Never store money as a binary floating-point value.
- Store an integer minor-unit amount together with an ISO 4217 currency code.
- Store timestamps as instants and retain the entry time-zone offset.
- Give every persistent entity a UUID and created/updated timestamps.
- Prefer soft deletion or an audit record for financial data.

## Structured import contract

JSON is the canonical interchange format. Every payload has a `schema_version`.
Import follows: parse, validate, show a human-readable preview, confirm, then
commit atomically. OCR and language models may produce this JSON later, but they
never bypass validation or write directly to the database.

CSV is a convenience export for analysis, not a lossless backup. A database
snapshot plus versioned JSON is the recovery format.

The first import schema accepts a single transaction object, an array, or the
canonical envelope below. Monetary values are decimal strings, timestamps are
ISO 8601, and category paths are `parent/child`. If an account name does not
exist, import creates it atomically. `account_kind` and `target_account_kind`
may specify `cash`, `bank`, `wallet`, `creditLine`, or `entrustedFunds`;
otherwise the importer infers a wallet for normal accounts and the required
liability/wallet roles for borrowing and repayment.

```json
{
  "schema_version": 1,
  "transactions": [
    {
      "type": "expense",
      "amount": "28.50",
      "occurred_at": "2026-09-09T12:30:00+08:00",
      "category": "饮食/午餐",
      "account": "支付宝",
      "account_kind": "wallet",
      "note": "午餐"
    },
    {
      "type": "borrowing",
      "amount": "1000.00",
      "occurred_at": "2026-09-09T13:00:00+08:00",
      "account": "朋友欠款",
      "account_kind": "creditLine",
      "target_account": "微信",
      "target_account_kind": "wallet",
      "note": "向朋友借款"
    }
  ]
}
```

Import is all-or-nothing. Parsed rows are shown in a preview where each row can
be edited or removed; repository balance rules run again inside the final
database transaction. New accounts are part of that same transaction, so a
failed batch leaves neither transactions nor orphaned accounts behind. When a
new asset account imports earlier spending, its opening balance is set to the
minimum amount required to keep the imported history valid.

## Reports

Daily, weekly, and monthly reports are computed views over source transactions.
The mobile report screen also includes yearly periods, income/expense balance,
borrowing and repayment totals, an expense trend, expense and income category
pie charts, and a liability trend.
Exports can cover the current week, month, year, all records, or a custom date
range in JSON, CSV, or Markdown, then use the platform share/save sheet.
They are not duplicated archive rows. Immutable report snapshots may be added
later if a real use case requires them.

## Category management

Expense and income categories can be created, renamed, reordered, and archived
at both levels. Creating a parent also creates a protected `其他` child. Archiving
never deletes category rows, so historical entries keep their original labels.
Restoring defaults only re-enables missing built-in categories and leaves custom
categories untouched.

## Transfers

`transfer` is a first-class transaction type for moving money between two
different personal asset accounts. It decreases the source and increases the
target by the same amount, does not affect income or expense reports, and is
rejected when the source balance is insufficient. Transfers to liabilities or
entrusted funds use their respective bookkeeping flows instead of masquerading
as account transfers.

## Complete backup and restore

The Summa full-backup JSON contains every account, opening balance,
category, entry, stable ID, archive flag, and soft-deletion flag. Replacement
restore recreates that snapshot exactly. Merge restore updates matching stable
IDs while preserving local-only rows. Both modes run in a database transaction;
the same session-level automatic-backup guard protects restore operations.

Local backup nodes are separated into automatic and manual groups. Once per app
session, the first successful ledger mutation preserves the state immediately
before that mutation; failed validation removes the tentative snapshot. The
automatic group retains the newest five nodes. Manual local nodes do not rotate
automatically and can be renamed, deleted, merged, or used for replacement
restore. Both groups live in app-private documents and are deleted by uninstall
or factory reset, so external export remains the durable off-device option.

Ledger reset removes every transaction, removes custom accounts, and restores
zero-balance default accounts while retaining categories and backup nodes.
Factory reset additionally restores default categories and removes all local
backup nodes. Both actions require an explicit destructive confirmation.
