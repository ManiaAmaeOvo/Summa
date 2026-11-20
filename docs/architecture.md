# Architecture

**English** | [简体中文](zh-CN/architecture.md)

## Technology

- Flutter and Dart for Android UI and the future cross-platform foundation.
- Material 3 for components and system-aware light and dark themes.
- Riverpod for dependency injection and reactive data subscriptions.
- Drift and SQLite for local persistence, migrations, and transactions.
- Flutter localization resources (ARB) for English and Simplified Chinese.
- Shared Preferences for the explicit language preference.
- `share_plus` for platform share and save flows.
- `file_picker` for selecting external complete backups.
- `package_info_plus` for installed version information.

## Dependency direction

```text
features -> app/providers -> domain <- data
                       \-> l10n
```

- `domain` defines accounts, categories, transactions, and interchange models.
- `data` implements repository contracts and accounting constraints with Drift.
- `features` reads and mutates data only through repositories and providers.
- SQLite is the local source of truth. Reports are computed from transactions
  instead of storing duplicate summaries.
- A repository decorator creates a complete snapshot before the first
  successful mutation in an app session. Failed mutations remove the tentative
  snapshot, so rejected validation does not consume an automatic slot.
- ARB resources own fixed UI copy. Stable default entity IDs let the
  presentation layer display untouched defaults in either language without
  changing user-authored names or breaking existing backups.

## Source layout

```text
lib/
  app/                       # App entry, providers, locale state, and theme
  core/                      # Money and other shared primitives
  domain/                    # Accounts, categories, transactions, import/export
  data/                      # Drift schema, migrations, backup store, repositories
  features/                  # Dashboard, editor, accounts, reports, and settings
  l10n/                      # ARB resources and localization helpers
```

## Core ledger constraints

- Amounts use integer minor units per currency. Posted transactions have
  balanced postings in each currency. Pending transactions affect balances
  after confirmation.
- Personal asset payments validate available funds. Repayments and collections
  validate the outstanding amount. Cross-currency transfers keep both actual
  settlement amounts, and valuation rates are stored separately.
- Accounts, categories, and transactions keep stable IDs. Refunds and reversals
  link to their original entries, and balance checkpoints can link to adjustments.
- Batch import, reviewed posting, and full restoration use database transactions.
- Resettable allowances are stored as account-linked plans. Payment validation
  and display use the same cycle limit and posted account legs. Date boundaries
  determine resets. Reconciliation continues to use the original ledger postings.

## Localization model

The language selector supports system, English, and Simplified Chinese. The
choice is persisted outside the financial database so a ledger restore does not
silently change interface preferences.

Default accounts and categories retain stable IDs and stored fallback names.
When a stored name still matches a known English or Chinese default alias, the
UI renders the label in the active language. Once a user renames it to a custom
value, that exact name is preserved across language changes. JSON import accepts
both default-language aliases while protocol keys and enum values stay English.

## Database versions

The current SQLite schema is 20. Versions 6–8 backfill and preserve postings,
9 adds settlement values, 10 adds valuation, 11–15 add funding attribution,
receivables, checkpoints, CSV batches, and rules, and 16–19 add financial plans.
Version 20 expands rules with compound conditions. See the
[2.0 implementation record](v2/PROGRESS.md) for migration details.

The app can restore Summa V1–15 and LedgerPro V1 backups. It writes V15 when the
ledger has a resettable allowance plan and V14 otherwise. Both use Schema 20.

## Local backups

Complete backups use versioned JSON. The app-specific documents directory keeps
up to five cross-launch snapshots under `summa_backups/automatic` and unlimited
user-managed snapshots under `summa_backups/manual`.

Both groups support replace restore, merge, and delete; manual snapshots can
also be renamed. Backup files are not stored inside the ledger database, which
prevents a backup from recursively containing itself.

Resetting transactions and accounts clears transactions, removes custom
accounts, and restores zero-balance defaults while preserving categories and
local backups. Factory reset also restores default categories and deletes all
in-app snapshots. Files exported outside the app are not affected.
