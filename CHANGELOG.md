# Changelog

**English** | [简体中文](CHANGELOG.zh-CN.md)

This project follows semantic versioning. The Android build number appears
after `+` in the Flutter version.

## [0.4.0] - 2026-09-10

### Added

- English and Simplified Chinese UI with follow-system and explicit language
  selection.
- Localized untouched default account and category labels without rewriting
  user-authored names.
- English and Chinese default-name aliases for JSON import.
- Parallel English and Simplified Chinese repository documentation.

### Changed

- GitHub renders the English README and user guide by default, with language
  links to the complete Chinese versions.
- Human-readable reports, dates, import feedback, and exports follow the active
  app language while JSON protocol keys remain stable.

## [0.3.0] - 2026-09-10

### Added

- One automatic backup before the first successful change after each launch,
  retaining the latest five snapshots.
- Manual local snapshots with restore, merge, rename, and delete controls.
- Separate reset-transactions-and-accounts and factory-reset scopes.
- A complete repository user guide and offline in-app help.

### Changed

- Data & Backup now separates automatic snapshots, manual local snapshots, and
  external import/export, and displays the app-specific backup directory.

## [0.2.0] - 2026-09-09

### Added

- Two-level expense and income category management.
- Transfers between personal asset accounts.
- Complete ledger backup with preview, merge restore, and replace restore.
- Automatic safety backup before restoration.
- Income and expense category charts and a liability trend.
- Settings, version, overview, and developer information.
- Summa launcher branding.

### Changed

- Renamed the development project from LedgerPro to Summa while preserving
  internal compatibility identifiers.
- JSON import can atomically create unknown accounts.
- Updated Material 3 theme, cards, navigation, and form controls.

## [0.1.0] - 2026-09-09

### Added

- Local accounts, liabilities, two-level categories, and transactions.
- Expense, income, borrowing, repayment, editing, and soft deletion.
- Period summaries, JSON batch import, and multi-format transaction export.
