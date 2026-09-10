# Development and Release Guide

**English** | [简体中文](zh-CN/development.md)

## Environment

- macOS; Apple Silicon is the primary development environment.
- Flutter stable and its bundled Dart SDK.
- Android SDK, platform-tools, and accepted Android SDK licenses.
- JDK 17.

```bash
flutter doctor -v
flutter devices
flutter pub get
flutter gen-l10n
flutter run
```

## Localization workflow

Fixed UI copy lives in `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb`.
Add a key and its placeholder metadata to both files, regenerate localization
code, and test both explicit languages. Do not localize JSON protocol keys,
enum values, user notes, or custom account and category names.

```bash
flutter gen-l10n
```

Untouched default entity labels are resolved through their stable IDs in
`lib/l10n/default_ledger_labels.dart`. When adding a new default entity, add its
English and Chinese aliases there and cover import and duplicate detection.

## Quality checks

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Tests cover money precision, account balances, borrowing and repayment,
transfers, category archiving, batch import, bilingual default aliases,
localized UI layout, complete backup restoration, and key widget lifecycles.

## Build an Android APK

```bash
flutter build apk --release
```

The output is `build/app/outputs/flutter-apk/app-release.apk`.

To validate an upgrade over an existing test build while preserving private app
data, use Android platform-tools:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Do not use `flutter install` for migration verification because it may uninstall
the previous build and clear local test data.

The current release build still uses a development signing configuration and is
suitable for direct testing. Before wider distribution, create and securely
store a dedicated upload key and reference it through an untracked
`key.properties` file.

## Version and release checklist

1. Update `version: x.y.z+build` in `pubspec.yaml`.
2. Update both `CHANGELOG.md` and `CHANGELOG.zh-CN.md`.
3. Run localization generation, formatting, analysis, and all tests.
4. Test English, Simplified Chinese, and follow-system behavior on an emulator.
5. Install the APK over the previous version and verify existing data.
6. Export a backup, restore it in both modes, and confirm language preference is
   independent from financial data.
7. Build the final APK, compute its SHA-256 digest, and publish a signed Git tag
   and GitHub Release.
