# JSON Import Protocol

**English** | [简体中文](zh-CN/json-import.md)

Summa accepts one transaction object, an array of transactions, or the canonical
`schema_version` envelope. The UI parses and previews every row before a single
atomic database write occurs.

Protocol field names and enum values are always English and do not change with
the app language.

## Common fields

| Field | Type | Description |
|---|---|---|
| `type` | string | `expense`, `income`, `transfer`, `borrowing`, or `repayment` |
| `amount` | string | Positive decimal CNY amount with at most two decimal places |
| `occurred_at` | string | ISO 8601 timestamp; include a timezone offset when possible |
| `account` | string | Source or posting account name |
| `account_kind` | string? | Type for a new account; optional |
| `target_account` | string? | Required for transfer, borrowing, and repayment |
| `target_account_kind` | string? | Type for a new target account; optional |
| `category` | string? | Required for expense and income; `Primary/Secondary` |
| `note` | string? | Up to 200 characters |

Allowed account kinds are `cash`, `bank`, `wallet`, `creditLine`, and
`entrustedFunds`. An ordinary unknown account defaults to `wallet`. A borrowing
source and repayment target default to `creditLine`.

Unknown accounts appear in preview as accounts to be created. The same unknown
name is created only once within a batch. New accounts and transactions share
the final database transaction, so a failed batch leaves no orphaned account.

Unknown categories are never created silently because an OCR or model typo
would pollute the category tree. Create the category first or correct the JSON
or preview selection.

Use **Copy template** in the import screen to obtain an LLM-oriented comment
prompt containing the ledger's current income and expense category paths,
followed by valid fenced JSON. `/` is reserved for separating the primary and
secondary names; neither individual name may contain `/`. Summa accepts the
entire copied text and extracts the JSON fence, so the prompt does not need to
be removed before import.

Untouched default accounts and categories can be referenced using either their
English or Simplified Chinese names. Custom and explicitly renamed items match
their stored names exactly.

## Transaction flow

- `expense`: spend from `account`.
- `income`: add income to `account`; a liability account is reduced instead.
- `transfer`: move money from personal asset `account` to personal asset
  `target_account`.
- `borrowing`: increase liability `account` and add the same amount to personal
  asset `target_account`.
- `repayment`: pay from personal asset `account` and reduce liability
  `target_account`.

## Canonical envelope

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

Imports are limited to 500 transactions per batch. Balance validation runs
again during final commit, even after preview, so JSON, OCR, or model output
cannot bypass ledger safety rules.
