# Summa

**English** | [简体中文](README.zh-CN.md)

A local-first personal finance ledger for Android.

Summa requires no account and no backend server. Accounts, liabilities,
categories, transactions, and in-app backups remain in the device's local
SQLite database unless you explicitly export or share them.

> Legacy migration baseline [`v0.4.2`](https://github.com/ManiaAmaeOvo/Summa/releases/tag/v0.4.2)
> (`0.4.2+6`). This branch documents Summa 2.0 and its development builds.

## Why Summa exists

Summa grew out of a personal ledger built with Python, NumPy, and Markdown.
That tool worked through a command line or a Web UI backed by an always-on
server, so it was not truly portable or offline. Summa is a clean Flutter
implementation designed for Android first, with desktop and iOS support left
open for future development.

The Summa 2.0 development build uses the Android application ID
`com.maniaamae.summa` and installs alongside releases through v0.4.2. To
transfer your ledger, export a complete JSON backup from **Settings → Data &
backup** in the old app and restore that file from the same screen in the new
app. Verify the restored accounts and transactions before uninstalling the old
app.

## Features

- Multi-currency accounts, split payments, partial refunds, pending entries,
  settlement amounts, and separate valuation rates.
- Funding attribution for personal, family, and entrusted payments, with
  advances, receivables, and collections.
- Budgets, monthly resettable card allowances, recurring plans, subscriptions,
  debt and receivable contracts, and savings goals.
- Generic CSV and WeChat Pay or Alipay statement import with rule previews,
  manual review, matching, and batch undo.
- JSON code import with a template for OCR and language models.
- Reconciliation, cash forecasting, multidimensional and historical reports,
  and JSON, CSV, XLSX, and Markdown financial report exports.
- Full backup and replace or merge restore, including older backups.
- Offline core functionality, English and Simplified Chinese, dark mode,
  and font-size controls.

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

1. Check your currency balances in **Accounts**. Set a Family Card allowance
   from the account menu.
2. Tap **Add transaction** on Home, or use a file or JSON import in **Transactions**.
3. Manage plans in **Planning**, and check spending and cash flows in **Reports**.
4. Save a full JSON backup outside Summa from **Settings → Data & backup**.

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
