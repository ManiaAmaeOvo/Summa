# Summa User Guide

**English** | [简体中文](USER_GUIDE.zh-CN.md)

Summa is a local-first personal ledger. It requires no sign-in and no backend
server. Accounts, categories, transactions, and in-app backups remain on the
current device unless you explicitly export or share them.

> This guide covers Summa `0.4.1`. A ledger and its complete backups may contain
> sensitive financial information. Do not publish real screenshots, JSON, or
> backup files in a public issue without removing private data.

## 1. Getting started

On first launch, Summa creates default asset accounts, liability accounts, and
two-level income and expense categories. A practical setup order is:

1. Open **Accounts** and calibrate the actual balance of Cash, Bank Account,
   Alipay, WeChat Pay, and any other accounts you use.
2. Archive defaults you do not need and add your own accounts.
3. Open **Settings → Category management** and review both category trees.
4. Return to the home screen and tap **Add transaction**.
5. After recording several transactions, inspect **Reports** to verify the
   categories and account flows.
6. Export a complete backup from **Settings → Data & backup** after entering
   important information.

Amounts are stored as integer minor units rather than floating-point values.
Expenses, repayments, and transfers validate available balances. A personal
asset account cannot be spent below zero, and a liability cannot be repaid by
more than its outstanding amount.

## 2. Language

Open **Settings → Language** and choose:

- **Follow system**: use the Android system language.
- **English**: always display the English interface.
- **Simplified Chinese**: always display the Simplified Chinese interface.

The selection is stored locally and takes effect immediately. Untouched default
account and category names follow the selected language. A name you explicitly
rename, as well as every custom name and transaction note, remains exactly as
you entered it and is never machine-translated.

Open **Settings → Font size** to follow the Android system setting or choose
Small, Standard, Large, or Extra large for Summa only. The selection takes
effect immediately and is retained after restarting the app.

Tapping the **Liquid net worth** summary card on the home screen opens the
Accounts page, where all four balance groups and individual accounts are shown.

## 3. Accounts and liabilities

The Accounts tab separates money into four summaries:

- **Personal liquid assets**: cash, bank accounts, Alipay, WeChat Pay, and other
  balances that belong to you.
- **Outstanding liabilities**: Huabei, Baitiao, monthly-pay services, personal
  loans, and other amounts that still need to be repaid.
- **Liquid net worth**: personal liquid assets minus outstanding liabilities.
- **Entrusted / authorized funds**: family cards, purchasing budgets, and other
  money you may use but do not fully own.

Fixed assets are intentionally outside the current default balance model.
Summa's headline balance focuses on available liquid money. This avoids making
a phone, computer, or other hard-to-sell property look like spendable cash.

### Calibrate a balance

Tap an account, enter its actual current balance, and save. Calibration adjusts
the opening balance. It does not fabricate an income or expense transaction, so
reports are not distorted.

### Add an account

Tap **Add account**, enter a unique name, select an account type, and optionally
enter its current balance:

- Cash
- Bank account
- Payment wallet
- Liability account
- Entrusted / authorized funds

An account name must be unique. Summa treats the English and Chinese labels of
an untouched default account as the same name, preventing accidental duplicates
after a language switch.

### Archive and restore defaults

The account action menu can archive an account. Archiving removes it from new
transaction selectors and current balance summaries without breaking historical
transactions. **Restore defaults** re-enables missing defaults without changing
existing balances, custom accounts, or transaction history.

## 4. Add a transaction

Tap **Add transaction** on the home screen and choose one of five transaction
types. The current time is selected by default and can be edited. Notes can
store a merchant, purpose, explanation, or other context.

### Expense

Choose a positive amount, a secondary expense category, and a payment account.
For example: `Food / Lunch`, Alipay, `28.50`.

An expense from a personal asset or entrusted-fund account requires a sufficient
balance. An expense paid through a liability account increases the amount owed.

### Income

Choose a positive amount, a secondary income category, and the destination
account. Income categories include earned income as well as family support,
living allowance, gifts, purchase remainder, refunds, and reimbursements.

Recording income directly into a liability account reduces that liability
instead of increasing cash. The reduction cannot exceed the outstanding amount.

### Borrowing

Borrowing connects a liability source to the personal asset account receiving
the money. For example:

```text
Loan from a friend → WeChat Pay, ¥1,000.00
```

After saving, the WeChat Pay balance increases by ¥1,000.00 and the personal
loan liability also increases by ¥1,000.00. This is not income and therefore
does not increase liquid net worth. A new liability account can be quick-added
from the editor.

### Repayment

Repayment connects a personal asset account to the liability being reduced. For
example: `Bank Account → Huabei`. It is neither new income nor a new expense.
Summa rejects the transaction if the payment balance is insufficient or the
amount exceeds the outstanding liability.

### Transfer

A transfer moves money between two different personal asset accounts, such as
`Bank Account → Alipay`. It does not appear in income or expense totals. The
source account must have enough money.

## 5. Edit and delete transactions

Tap an existing transaction on the home screen to open it in the editor. Amount,
time, category, accounts, flow direction, and note are updated as one operation.
Summa recalculates and validates the complete affected ledger before accepting
the change.

Deleting a transaction uses a soft delete. It disappears immediately from the
home screen, reports, and balance calculations, while the database retains the
minimum historical state required for backup compatibility and consistency.
Soft-deleted rows do not remain in memory; they only cause gradual SQLite file
growth over long-term use.

## 6. Two-level categories

Open **Settings → Category management** to maintain separate trees for income
and expenses:

```text
Primary category → Secondary category
```

A transaction selects a secondary category; Summa derives its primary category
for summaries and charts. Both levels support adding, renaming, ordering, and
archiving. Every primary category retains an **Other** fallback. Historical
transactions continue displaying an archived category. At both levels,
**Other** remains the final item; a newly created category is inserted above it.

**Restore default categories** only re-enables or recreates missing defaults. It
does not delete custom categories.

## 7. JSON code import

Tap the code icon in the top-right of the home screen. This workflow is designed
for transaction screenshots that have been converted to strict JSON by OCR or a
language model.

The import sequence is:

```text
Paste JSON → Parse and validate → Preview and edit → Confirm count → Atomic write
```

**Copy template** copies an LLM-ready prompt followed by valid fenced JSON. The
prompt includes the category paths currently available in this ledger and tells
the model that `/` is reserved as the separator in `Primary/Secondary`; an
individual category name cannot contain `/`. The whole copied text can be pasted
back into Summa because import ignores the prompt comment around the JSON fence.

Before confirmation, tap any item to edit it or remove it from the batch. The
write is atomic: either every valid item and confirmed new account is committed,
or nothing is written.

### Batch example

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
    },
    {
      "type": "borrowing",
      "amount": "1000.00",
      "occurred_at": "2026-09-09T13:00:00+08:00",
      "account": "Loan from a friend",
      "account_kind": "creditLine",
      "target_account": "WeChat Pay",
      "target_account_kind": "wallet",
      "note": "Short-term loan"
    }
  ]
}
```

Supported `type` values are `expense`, `income`, `transfer`, `borrowing`, and
`repayment`. Amounts are positive decimal strings, timestamps use ISO 8601, and
categories use `Primary/Secondary`. Protocol field names and enum values always
remain English so JSON is stable across language settings.

Both English and Chinese aliases are accepted for untouched default accounts and
categories. Unknown accounts are marked for creation in the preview. Unknown
categories are not silently created because OCR spelling errors would pollute
the category tree; create the category first or correct it in preview.

See the [complete JSON import protocol](docs/json-import.md).

## 8. Reports and transaction export

The Reports tab provides daily, weekly, monthly, and yearly views including:

- Income, expense, borrowing, and repayment totals.
- Income and expense category pie charts.
- Expense trend and liability trend, with approximate dates on the horizontal
  axis and amounts on the vertical axis.

Export transactions for this week, month, year, all time, or a custom date range:

- **JSON**: structured and re-importable.
- **CSV**: suitable for Excel, Numbers, and other spreadsheet tools.
- **Markdown**: readable in notes and convenient for language-model analysis.

Human-readable headings and untouched default labels follow the selected app
language. JSON protocol keys remain language-neutral English. A transaction
export contains only the chosen transaction range and is not a complete app
backup.

## 9. Automatic and manual backups

Open **Settings → Data & backup** to view the actual backup directory and both
automatic and manual local snapshots.

### Automatic snapshots

Before the first successful change to transactions, accounts, or categories
after each launch, Summa saves the complete previous state. Invalid or rejected
operations do not leave a snapshot. Later changes during the same launch do not
create more automatic snapshots. The newest five launch snapshots are retained;
the sixth removes the oldest.

### Manual local snapshots

Tap **Back up inside the app**, enter a name, and save. Manual snapshots are not
limited by the five automatic slots. Tap a snapshot to preview and replace the
current ledger. Its menu also supports merge, rename, and delete.

### Export or share a complete backup

Tap **Export or share backup** and use the Android system sheet to save it to a
downloads folder, cloud drive, or other trusted destination. An external file
survives Summa uninstall and factory reset and is therefore the correct choice
for long-term retention.

### Replace versus merge

- **Replace & restore** makes the current ledger exactly match the snapshot.
- **Merge** updates items with the same stable ID and preserves data unique to
  the current device. Use it when combining related copies of a ledger.

Automatic and manual snapshots are stored under the app-specific
`summa_backups` directory shown on the page. Android 11 and later normally
restrict ordinary file managers from browsing private app storage. Manage these
snapshots inside Summa, and export externally before uninstalling.

## 10. Reset data

The bottom of **Settings → Data & backup** offers two separately confirmed
operations:

- **Reset transactions & accounts** permanently clears every transaction,
  deletes custom accounts, and restores default accounts with zero balances. It
  preserves income and expense categories and all local backups.
- **Factory reset** clears transactions, accounts, custom categories, and every
  in-app backup, returning Summa to first-install state. Files already exported
  outside the app are not affected.

If the goal is to return to a known earlier state, restore a backup snapshot
instead of resetting.

## 11. Data safety and common questions

### Does Summa require a network connection or server?

No for core functionality. Opening the developer's GitHub profile or choosing a
network share target is an explicit user action and does not affect offline
ledger use.

### Does data survive uninstall?

Normally not. Android removes the app database and in-app snapshots. Export a
complete backup and verify that it exists outside Summa before uninstalling or
changing devices.

### Why can an account not become negative?

For a personal liquid asset, a negative value usually means the payment source
was recorded incorrectly or the opening balance was not calibrated. Liabilities
are modeled separately so debt is not hidden inside a negative asset balance.

### Does soft deletion eventually use storage?

Yes, slowly. Deleted rows remain in SQLite for consistency and backup history,
but they are not loaded into active transaction lists. Ordinary personal use is
unlikely to create meaningful storage pressure. A future maintenance tool can
compact old deleted records if real-world usage shows a need.

### Which format should I use with a language model?

Use strict JSON for importing because Summa validates it field by field. Use a
Markdown or CSV transaction export when asking a model to summarize or analyze
a period. Never upload a complete real backup to an untrusted service.

## 12. Troubleshooting

- If a save is rejected, read the message inside the open editor. It identifies
  insufficient balance, overpayment, or a missing selection.
- If JSON cannot be parsed, copy the in-app template, keep numeric amounts inside
  quotes, and use ISO 8601 timestamps with a timezone offset.
- If a default English account or category is not found, verify that the default
  was not explicitly renamed. Custom names are matched exactly.
- If a local backup is not visible in a file manager, manage it inside Summa or
  use **Export or share backup**.
- If an external backup fails validation, the current database is left unchanged.
