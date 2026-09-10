# Contributing to Summa

**English** | [简体中文](CONTRIBUTING.zh-CN.md)

Thank you for helping improve Summa.

## Reporting an issue

Include the device model, Android version, Summa version, reproduction steps,
expected result, and actual result. Ledger screenshots and backups may contain
private information. Redact them first and never upload a real complete backup
to a public issue.

## Contributing code

1. Create a short-lived feature branch from the latest default branch.
2. Keep accounting rules in the repository/domain boundary rather than only in
   widgets.
3. Add tests for ledger rules, migrations, localization, or bug fixes.
4. Add every fixed UI message to both English and Chinese ARB resources.
5. Preserve stable JSON protocol keys and existing backup compatibility.
6. Run `flutter gen-l10n`, formatting, analysis, and all tests.
7. Explain behavior changes, data compatibility, and manual verification in the
   pull request.

Do not commit APKs, SDK caches, signing keys, real ledgers, or personal financial
data.
