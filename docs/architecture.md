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

- CNY amounts are stored as integer minor units, never binary floating point.
- Expenses and transfers cannot exceed the source asset balance.
- Repayment cannot exceed either the payment balance or target liability.
- Transfers are limited to two different personal asset accounts and do not
  affect income or expense totals.
- Archived accounts, categories, and soft-deleted transactions retain stable
  historical references.
- Batch import and backup restore execute inside one database transaction.

## Localization model

The language selector supports system, English, and Simplified Chinese. The
choice is persisted outside the financial database so a ledger restore does not
silently change interface preferences.

Default accounts and categories retain stable IDs and stored fallback names.
When a stored name still matches a known English or Chinese default alias, the
UI renders the label in the active language. Once a user renames it to a custom
value, that exact name is preserved across language changes. JSON import accepts
both default-language aliases while protocol keys and enum values stay English.

## Database version

The current schema version is 6:

- v1: accounts, two-level expense categories, and transactions.
- v2: entrusted funds and `Other` secondary categories.
- v3: additional default liability accounts.
- v4: transaction soft deletion.
- v5: target accounts and income, borrowing, and repayment system categories.
- v6: personal account transfer categories.

The `0.4.0` localization design does not rewrite financial rows or require a
schema migration. Any future schema change must increment the version, include a
forward migration, and add automated coverage.

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
