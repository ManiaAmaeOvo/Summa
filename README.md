# Summa

**English** | [简体中文](README.zh-CN.md)

A local-first personal finance ledger for Android.

Summa requires no account and no backend server. Accounts, liabilities,
categories, transactions, and in-app backups remain in the device's local
SQLite database unless you explicitly export or share them.

> Latest stable release: [`v0.4.1`](https://github.com/ManiaAmaeOvo/Summa/releases/tag/v0.4.1)
> (`0.4.1+5`). Export a complete backup regularly when using important data.

## Why Summa exists

Summa grew out of a personal ledger built with Python, NumPy, and Markdown.
That tool worked through a command line or a Web UI backed by an always-on
server, so it was not truly portable or offline. Summa is a clean Flutter
implementation designed for Android first, with desktop and iOS support left
open for future development.

The project used the working name `LedgerPro` during early development. Some
non-user-facing identifiers retain that name so existing test installations
and backups remain compatible.

## Features

- Expense, income, borrowing, repayment, and personal-account transfers.
- Separate two-level category trees for income and expenses, with add, rename,
  ordering, and archive controls; `Other` always stays last.
- Cash, bank, wallet, entrusted or authorized funds, and liability accounts.
- Hard validation for insufficient balances and liability overpayment.
- Daily, weekly, monthly, and yearly summaries; category pie charts and scaled
  expense/liability trend charts.
- Strict single or batch JSON import with an LLM-ready template, editable
  preview, and atomic writes.
- Automatic creation of confirmed unknown accounts during JSON import.
- Transaction export by date range in JSON, CSV, or Markdown.
- Complete backup with replace or merge restore and a safety snapshot before
  restoration.
- One automatic snapshot before the first successful change after each launch,
  with the latest five automatic snapshots retained.
- Named manual local snapshots with preview, rename, merge, restore, and delete.
- English and Simplified Chinese UI with a persistent in-app language selector.
- Persistent app font-size controls from small through extra large, or follow
  the Android system setting.
- Fully offline core functionality.

## Install

Download the APK from [GitHub Releases](https://github.com/ManiaAmaeOvo/Summa/releases),
allow installation from unknown apps when Android asks, and install it.

A development build can also be installed with Flutter:

```bash
flutter pub get
flutter run
```

Android currently requires `minSdk 24` and targets SDK 36.

## Quick start

1. Open **Accounts** and calibrate the current balances for cash, bank,
   payment-wallet, entrusted-fund, and liability accounts.
2. Tap **Add transaction** on the home screen and choose Expense, Income,
   Borrowing, Repayment, or Transfer.
3. Open **Settings → Category management** to maintain the two-level income
   and expense categories.
4. Use the code icon in the top-right of the home screen to paste strict JSON,
   preview the parsed transactions, and import them as one atomic batch.
5. Open **Reports** for daily, weekly, monthly, or yearly summaries and export
   JSON, CSV, or Markdown for a selected period.
6. Open **Settings → Data & backup** to manage automatic and manual snapshots,
   external backups, restore, merge, and reset operations.
7. Open **Settings → Language** to follow the system language or explicitly use
   English or Simplified Chinese.
8. Open **Settings → Font size** to follow Android or choose a size used only
   inside Summa. Tap **Liquid net worth** on the home screen to open Accounts.

See the [complete user guide](USER_GUIDE.md) for ledger semantics, import
examples, backup behavior, recovery options, and common questions. The same
core guidance is available offline inside Summa.

## JSON import example

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
      "type": "transfer",
      "amount": "100.00",
      "occurred_at": "2026-09-09T13:00:00+08:00",
      "account": "Alipay",
      "target_account": "WeChat Pay",
      "note": "Balance transfer"
    }
  ]
}
```

The protocol keywords remain English and language-neutral. Summa accepts both
English and Chinese aliases for untouched default accounts and categories.
Unknown accounts can be created during import; unknown categories must be
corrected or created before confirmation. See the
[JSON import protocol](docs/json-import.md) for every field and validation rule.

## Technology

- Flutter and Dart
- Material 3
- Riverpod
- Drift and SQLite
- `share_plus`, `file_picker`, `shared_preferences`, and `package_info_plus`

See the [architecture](docs/architecture.md),
[product foundation](docs/product-foundation.md), and
[development guide](docs/development.md) for implementation details.

## Local development

```bash
flutter pub get
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release
```

CI runs formatting, analysis, and tests on pushes to `main` and pull requests.

## Data and privacy

- Summa currently contains no analytics SDK, advertising SDK, or remote account
  service.
- It does not upload the ledger. Network-capable share targets are invoked only
  after an explicit export or share action.
- Android normally removes the private app directory during uninstall. Export a
  complete backup first.
- Complete backups contain sensitive financial information and should be kept
  only in trusted locations.
- Automatic and manual snapshots live in the app-specific `summa_backups`
  directory shown under **Settings → Data & backup**. Recent Android file
  managers may not expose that private directory directly.

## Project status and roadmap

- Continue real-device, accessibility, large-text, and small-screen testing.
- Improve category mapping and batch correction during import.
- Add optional OCR and natural-language transaction parsing while preserving
  local validation and explicit confirmation.
- Explore desktop management and iOS support.

Changes are documented in the [changelog](CHANGELOG.md).

## Contributing and security

Issues, focused improvements, and pull requests are welcome. Read
[CONTRIBUTING.md](CONTRIBUTING.md) before contributing and use the private
contact guidance in [SECURITY.md](SECURITY.md) for sensitive reports.

## License

Summa is source-available under the
[PolyForm Noncommercial License 1.0.0](LICENSE). Noncommercial use, study,
modification, and redistribution are permitted under its terms, and the
license and required attribution notice must accompany copies.

Commercial use is not granted. This is a noncommercial source-available
license, not an OSI-approved open-source license. The English license text is
controlling; attribution details are in [NOTICE](NOTICE).

## Credits

Summa was initiated and is maintained by
[ManiaAmaeOvo](https://github.com/ManiaAmaeOvo), with OpenAI Codex used as a
development collaborator.
