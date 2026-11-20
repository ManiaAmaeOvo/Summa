# Summa 2.0 User Guide

**English** | [简体中文](USER_GUIDE.zh-CN.md)

Summa is a local ledger. Accounts, categories, transactions, and in-app backups
are kept on your device. You can use the app without signing in.

## 1. Start a ledger

1. Open **Accounts**, add or archive accounts, and calibrate actual balances in
   their currencies. Enter liabilities as positive amounts owed.
2. Review the two levels of income and expense categories in **Settings →
   Category management**.
3. Tap **Add transaction** on Home. Home also shows net worth, available funds,
   remaining budgets, upcoming obligations, and reconciliation items.
4. Check results in **Reports**, then export a full JSON backup from **Settings
   → Data & backup**.

Settings also contains language and font size. Untouched default names follow
the app language. Custom names keep their original spelling.
You can add, rename, reorder, or archive categories. Each parent keeps an
**Other** fallback. Archived categories remain visible on historical entries.

To migrate from LedgerPro or Summa 0.4.2, export a full JSON backup from the old
app and restore it in Summa 2.0. Both apps can be installed together. Verify
balances, transaction history, and refund and transfer links after restoring.

## 2. Accounts, currencies, and reconciliation

- Personal accounts include cash, bank accounts, wallets, savings, and prepaid
  assets. Liabilities show money you owe. Receivables show money owed to you.
- Family cards and money held for someone else belong to entrusted funds. Their
  balances and spending allowances are outside personal cash and net worth.
- Tap an account to calibrate its balance. The difference creates an auditable
  adjustment. Use **Reconciliation** in the account menu to compare an observed
  balance with the ledger at a specific time and decide whether to adjust it.
- Archiving removes an account from new transaction choices and preserves its
  history. **Restore defaults** re-enables missing default accounts.
- For a cross-currency transfer, enter the actual amount on each side. For a
  foreign purchase, enter the original price and the actual debit. The net worth
  card separately uses valuation rates in your chosen base currency and lists
  currencies whose rates are missing.

### Reset the Family Card to ¥1,000 each month

1. Open **Accounts → Family Card → ⋮ → Resettable allowance**. You can enable it
   on any account of the **Entrusted / authorized funds** type.
2. Enter `1000` and choose the first day of the applicable month. Subsequent
   cycles start on the same day, or the last day in a shorter month.
3. Select Family Card when entering a card purchase. A posted ¥200 purchase
   leaves ¥800 available. The following month starts at ¥1,000. Unused
   allowance expires.
4. Open the account’s allowance details to review prior cycles or change the
   limit for one cycle or for subsequent ones. If the account already has a
   tracked external allowance, archive that plan before enabling the resettable one.

The transaction date determines the cycle. Pending purchases use allowance when
posted. Card refunds restore availability in the refund’s cycle, up to its
limit. The ledger balance remains available for reconciliation. Transfers and
debt repayments continue to require ledger funds. Refreshing an allowance
creates no transaction, income, or change in net worth.

## 3. Record transactions and funding

- **Expense**. Select a category and payment account. You can split payments
  across accounts in the same currency. Use **Paid directly by family** for a
  purchase made directly by a family member. For a Family Card purchase, select
  the entrusted account itself.
- **Income**. Select the receiving account. Record cash you receive from family
  as family support or a living allowance if it belongs to you.
- **Transfer**. Move money between eligible accounts. Enter both actual
  settlement amounts if the currencies differ.
- **Borrowing / Repayment**. Borrowing increases both your cash and your debt.
  Repayment reduces cash and principal. Enter interest and fees separately.
- **Lending / Collect principal**. Record a loan from your personal account into
  a named receivable. Record principal collections against that receivable.
- **Refund**. Open the original expense’s menu. Record full or partial refunds
  against the original payment account.
- **Pending**. Save an unconfirmed transaction as pending. After checking the
  amount, accounts, category, and date, post it from the transaction menu.
- **Edit, delete, or reverse**. Tap a row to edit it and use its menu for other
  applicable actions.

### Advance for someone else

An advance means you paid on someone else’s behalf and expect reimbursement.
The amount moves from your payment account to a receivable in the same
currency. Your personal cash flow shows the money leaving and later returning.
Neither principal movement counts as income or consumption. The receivable
shows how much remains outstanding.

**Full advance.** You pay ¥80 for a friend’s ticket from WeChat Pay.

1. Choose **Add transaction → Advance**, select WeChat Pay as the source,
   create a **Friend receivable**, and enter ¥80. Posting moves ¥80 from WeChat
   Pay into the receivable.
2. When your friend returns ¥30, choose **Reimbursement**. Select the
   receivable as the source and WeChat Pay as the destination. The receivable
   still shows ¥50.
3. Record the final ¥50 with another **Reimbursement**.

**Shared bill.** You pay ¥200 for dinner and your share is ¥80. Record a ¥200
expense, enable **Part of this bill is owed by someone else**, and enter ¥120 against the
receivable. Summa records a ¥200 cash outflow, ¥80 of personal spending, and
¥120 receivable. Record reimbursement as it arrives.

Use **Expense** for a gift or a cost you bear yourself. Use the original
expense’s **Refund** action for money returned by a merchant. Use **Lending**
when you lend money directly.

## 4. Import statements

From **Transactions → CSV Import**, open a generic CSV or a WeChat Pay or
Alipay CSV/XLSX statement. Review duplicates, matches, category suggestions,
payment accounts, and dates. Select and confirm the rows you want to post. Open
the original statement from a transaction’s menu or undo a batch from import
history. Category rule previews show suggested categories before you approve
any transaction.

For screenshots, **Code import → Copy template** provides a JSON template with
current category names. An OCR tool or language model can fill it from
redacted screenshots. Review the parsed accounts, amounts, dates, and
categories before you confirm. Accounts marked for creation are created with
the batch. See the [JSON import protocol](docs/json-import.md).

**One payment notice (development build).** Open **Add transaction**, then
**Paste payment notice**. Paste a Chinese WeChat Pay or Alipay notice with an
explicit CNY amount. For example, put `微信支付` on the first line and
`支付金额：¥28.50` on the next. Select a CNY account, then choose **Review in
editor** and check the date, category, and duplicates. The entry defaults to
pending. Refunds, transfers, and ambiguous notices need manual entry. This
first version processes manually pasted text on the device.

## 5. Planning and reports

- **Planning** contains budgets, external allowances, recurring transactions,
  subscriptions, debt and receivable contracts, and savings goals. Confirm or
  link actual transactions when plans come due.
- **Cash forecast** projects balances and shortfalls by currency. It separates
  planned movements from already-posted transactions.
- **Reports** can filter by period, currency, category, account, funding, and
  statement fields. Open a category or account to see the matching
  transactions. **Historical analysis** compares periods.
- **Export financial report** uses the current filters and supports JSON, CSV,
  XLSX, and Markdown, with optional matching transactions.

## 6. Backup, restore, and reset

Full backups contain ledger entries and postings, accounts, categories, import
history, rates, reconciliation, and planning settings. Use **Data & backup** for
full restoration or migration. A financial report export contains the selected
report and can include its matching transactions.

- The first successful edit after each launch preserves the previous state.
  Summa keeps the five most recent automatic snapshots.
- Named in-app backups do not occupy automatic slots. Their menu supports
  merge, rename, and delete. Use **Export or share backup** to save a full
  copy outside Summa before changing devices or uninstalling.
- **Replace** restores the backup state. **Merge** incorporates compatible
  records by their stable IDs and keeps records unique to this device. Compare
  balances and transaction history after restoration.
- **Reset transactions and accounts** clears transactions, custom accounts, and
  account-linked plans. It keeps categories, other budgets, and backups.
  **Factory reset** also clears custom categories and in-app backups. Saved
  files outside Summa remain available.

## 7. Troubleshooting

- If a save is rejected, check the editor message for a balance, cycle
  allowance, outstanding principal, or required selection.
- If JSON fails to parse, copy the in-app template. Quote amounts and use ISO
  8601 timestamps with timezone offsets. Use the current names for custom
  accounts and categories.
- When working with a language model, use the JSON template for importing and
  CSV or Markdown for analyzing selected records. Remove private identifiers
  and notes before sharing and keep complete backups in trusted locations.
