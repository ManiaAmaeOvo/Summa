// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Summa';

  @override
  String get settings => 'Settings';

  @override
  String get ledger => 'Ledger';

  @override
  String get app => 'App';

  @override
  String get categoryManagement => 'Category management';

  @override
  String get categoryManagementSubtitle =>
      'Manage two-level income and expense categories';

  @override
  String get dataAndBackup => 'Data & backup';

  @override
  String get dataAndBackupSubtitle =>
      'Local snapshots, export, restore, and reset';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'Choose the language used by Summa';

  @override
  String get languageSystem => 'Follow system';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSimplifiedChinese => 'Simplified Chinese';

  @override
  String get userGuide => 'User guide';

  @override
  String get userGuideSubtitle => 'Features, instructions, and data safety';

  @override
  String get aboutSumma => 'About Summa';

  @override
  String get aboutSummaSubtitle =>
      'Version, overview, and developer information';

  @override
  String versionLabel(String version, String buildNumber) {
    return 'Version $version ($buildNumber)';
  }

  @override
  String get readingVersion => 'Reading version information…';

  @override
  String get aboutDescription =>
      'A completely local-first personal ledger. Accounts, liabilities, categories, and transactions stay on your device by default, with no sign-in or backend server required.';

  @override
  String get developer => 'Developer';

  @override
  String get builtWith => 'Built with';

  @override
  String get dataPrinciples => 'Data principles';

  @override
  String get dataPrinciplesValue =>
      'Local storage, explicit export, user-controlled';

  @override
  String get softwareLicense => 'Software license';

  @override
  String get softwareLicenseValue =>
      'PolyForm Noncommercial 1.0.0 · Noncommercial use only';

  @override
  String get cannotOpenGitHub => 'Could not open the GitHub profile';

  @override
  String get helpIntro =>
      'Summa works entirely locally. Start by calibrating account balances, review your categories, and then begin recording transactions. Export a complete backup regularly for important data.';

  @override
  String get helpTransactionsTitle => 'Transactions and types';

  @override
  String get helpTransactions1 =>
      'Tap “Add transaction” on the home screen to record an expense, income, borrowing, repayment, or transfer between personal accounts. The current time is selected by default and can be changed.';

  @override
  String get helpTransactions2 =>
      'Borrowing increases both a liability and the destination account balance and is not income. Repayment reduces both the payment balance and the liability and is not an expense. Transfers are excluded from income and expense totals.';

  @override
  String get helpTransactions3 =>
      'Insufficient balances, overpayment, and invalid account flows are rejected. Tap an existing transaction to edit or soft-delete it.';

  @override
  String get helpAccountsTitle => 'Accounts and categories';

  @override
  String get helpAccounts1 =>
      'The Accounts tab shows personal liquid assets, outstanding liabilities, liquid net worth, and entrusted or authorized funds. Tap an account to calibrate its current balance; calibration does not create artificial income or expenses.';

  @override
  String get helpAccounts2 =>
      'Accounts can be added or archived. Category management in Settings maintains separate two-level structures for income and expenses. Transactions use the second level, and every primary category keeps an “Other” fallback.';

  @override
  String get helpJsonTitle => 'JSON code import';

  @override
  String get helpJson1 =>
      'Use the code icon in the top-right of the home screen to paste one or many JSON transactions. This is useful after an OCR tool or language model structures a statement screenshot.';

  @override
  String get helpJson2 =>
      'The flow is parse and validate, preview and edit each item, confirm the count, then write atomically. Unknown accounts can be created automatically; unknown categories must be created first or corrected in the preview.';

  @override
  String get helpJson3 =>
      'Amounts are positive decimal strings, timestamps use ISO 8601, and categories use “Primary/Secondary”.';

  @override
  String get helpReportsTitle => 'Reports and export';

  @override
  String get helpReports1 =>
      'Reports supports daily, weekly, monthly, and yearly views with income and expense category charts, expense trends, and liability trends.';

  @override
  String get helpReports2 =>
      'Export transactions for this week, month, year, all time, or a custom range as JSON, CSV, or Markdown. Transaction exports are for analysis and are not complete restorable backups.';

  @override
  String get helpBackupTitle => 'Backup, merge, and restore';

  @override
  String get helpBackup1 =>
      'Before the first successful change after each launch, Summa automatically saves the complete previous state. Up to five automatic snapshots are kept, and failed operations do not consume a slot.';

  @override
  String get helpBackup2 =>
      'Manual backups can be saved inside the app or exported externally. Tap a local snapshot to preview and replace the ledger, or use its menu to merge, rename a manual snapshot, or delete it.';

  @override
  String get helpBackup3 =>
      'In-app snapshots live in the app-specific directory shown in Settings and are removed when the app is uninstalled or factory-reset. Use export or share for long-term storage.';

  @override
  String get helpResetTitle => 'Reset scope';

  @override
  String get helpReset1 =>
      '“Reset transactions & accounts” clears transactions and custom accounts and sets default accounts to zero, while preserving categories and backups.';

  @override
  String get helpReset2 =>
      '“Factory reset” also restores default categories and deletes every in-app backup. Externally exported files are not affected.';

  @override
  String get helpSecurityTitle => 'Data safety';

  @override
  String get helpSecurity1 =>
      'The ledger stays on this device by default. Uninstalling normally removes the database and local snapshots, so export a complete backup before uninstalling or changing devices.';

  @override
  String get helpSecurity2 =>
      'Complete backups contain sensitive financial information. Store them only in trusted locations and never upload a real backup to a public issue.';

  @override
  String get accountBalances => 'Account balances';

  @override
  String get reports => 'Reports';

  @override
  String get codeImport => 'JSON import';

  @override
  String get addTransaction => 'Add transaction';

  @override
  String get transactions => 'Transactions';

  @override
  String get accounts => 'Accounts';

  @override
  String get expenseThisMonth => 'Expense this month';

  @override
  String get expenseThisWeek => 'Expense this week';

  @override
  String get expenseAllTime => 'All-time expense';

  @override
  String get liquidNetWorth => 'Liquid net worth';

  @override
  String get transactionActions => 'Transaction actions';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirmDeleteTransaction => 'Delete this transaction?';

  @override
  String get deleteRecalculatesBalances =>
      'Related account balances will be recalculated after deletion.';

  @override
  String get transactionDeleted => 'Transaction deleted';

  @override
  String get deleteFailed => 'Could not delete. Please try again.';

  @override
  String get expense => 'Expense';

  @override
  String get income => 'Income';

  @override
  String get borrowing => 'Borrowing';

  @override
  String get repayment => 'Repayment';

  @override
  String get transfer => 'Transfer';

  @override
  String creditedTo(String account) {
    return 'Credited to $account';
  }

  @override
  String get noTransactions => 'No transactions yet';

  @override
  String get noTransactionsHint =>
      'Tap “Add transaction” to create your first local record.';

  @override
  String get ledgerReadFailed => 'Could not load the ledger';

  @override
  String get retry => 'Retry';

  @override
  String get accountBalanceReadFailed => 'Could not load account balances';

  @override
  String archiveAccountTitle(String account) {
    return 'Archive $account?';
  }

  @override
  String get archiveAccountDescription =>
      'The account will be removed from selection lists and balance totals, while historical transactions remain available. A default account can later be re-enabled with “Restore defaults”.';

  @override
  String get archive => 'Archive';

  @override
  String accountArchived(String account) {
    return '$account archived';
  }

  @override
  String get archiveFailed => 'Could not archive. Please try again.';

  @override
  String get defaultAccountsRestored =>
      'Default accounts restored without changing existing balances';

  @override
  String get restoreFailed => 'Could not restore. Please try again.';

  @override
  String get personalLiquidAssets => 'Personal liquid assets';

  @override
  String get outstandingLiabilities => 'Outstanding liabilities';

  @override
  String get entrustedFunds => 'Entrusted / authorized funds';

  @override
  String get addAccount => 'Add account';

  @override
  String get restoreDefaults => 'Restore defaults';

  @override
  String get personalAccounts => 'Personal accounts';

  @override
  String get personalAccountsDescription =>
      'Cash, bank, and wallet balances you own';

  @override
  String get entrustedFundsDescription =>
      'Available to use but excluded from personal assets';

  @override
  String get liabilityAccounts => 'Liability accounts';

  @override
  String get liabilityAccountsDescription => 'Amounts currently owed';

  @override
  String get accountCalibrationHint =>
      'Tap an account to calibrate its current balance. Future expenses subtract from asset accounts or increase the balance owed on liability accounts.';

  @override
  String get addAccountOrLiability => 'Add account or liability';

  @override
  String get name => 'Name';

  @override
  String get liabilityNameExample => 'For example: Loan from a friend';

  @override
  String get assetNameExample => 'For example: Savings account';

  @override
  String get accountingType => 'Account type';

  @override
  String get currentAmountOwed => 'Current amount owed';

  @override
  String get currentBalance => 'Current balance';

  @override
  String get zeroThenCalibrate => 'You can enter 0 and calibrate it later';

  @override
  String get adding => 'Adding…';

  @override
  String get add => 'Add';

  @override
  String get enterName => 'Enter a name';

  @override
  String get nameAlreadyExists => 'That name already exists';

  @override
  String get addFailed => 'Could not add. Please try again.';

  @override
  String get accountKindCash => 'Cash';

  @override
  String get accountKindBank => 'Bank account';

  @override
  String get accountKindWallet => 'Payment wallet';

  @override
  String get accountKindEntrustedFunds => 'Entrusted / authorized funds';

  @override
  String get accountKindLiability => 'Liability account';

  @override
  String calibrateLiability(String account) {
    return 'Calibrate $account liability';
  }

  @override
  String calibrateBalance(String account) {
    return 'Calibrate $account balance';
  }

  @override
  String get nonNegativeTwoDecimals =>
      'Must not be negative; up to two decimal places';

  @override
  String get saving => 'Saving…';

  @override
  String get save => 'Save';

  @override
  String get saveFailed => 'Could not save. Please try again.';

  @override
  String get liability => 'Liability';

  @override
  String get balance => 'Balance';

  @override
  String get accountActions => 'Account actions';

  @override
  String get archiveAccount => 'Archive account';

  @override
  String get moneyInvalidFormat =>
      'Enter a valid amount with up to two decimal places';

  @override
  String get moneyNotNegative => 'Amount must not be negative';

  @override
  String get moneyGreaterThanZero => 'Amount must be greater than zero';

  @override
  String get restoreDefaultCategories => 'Restore default categories';

  @override
  String get restoreDefaultCategoriesTitle => 'Restore default categories?';

  @override
  String get restoreDefaultCategoriesDescription =>
      'Only missing default categories will be re-enabled. Custom categories will not be deleted or reset.';

  @override
  String get restore => 'Restore';

  @override
  String get defaultCategoriesRestored =>
      'Default categories restored; custom categories were not changed';

  @override
  String get categoryReadFailed => 'Could not load categories';

  @override
  String get categoryStructureHint =>
      'Primary categories are used for totals, while secondary categories are used by transactions. Historical transactions keep the names of archived categories.';

  @override
  String get addPrimaryCategory => 'Add primary category';

  @override
  String secondaryCategoryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count secondary categories',
      one: '1 secondary category',
      zero: 'No secondary categories',
    );
    return '$_temp0';
  }

  @override
  String get rename => 'Rename';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get archiveCategory => 'Archive category';

  @override
  String get addSecondaryCategory => 'Add secondary category';

  @override
  String addToCategory(String category) {
    return 'Add to “$category”';
  }

  @override
  String get renamePrimaryCategory => 'Rename primary category';

  @override
  String get renameSecondaryCategory => 'Rename secondary category';

  @override
  String archiveCategoryTitle(String category) {
    return 'Archive “$category”?';
  }

  @override
  String get archivePrimaryCategoryDescription =>
      'This primary category and its secondary categories will no longer be available for new transactions. Historical transactions are not affected.';

  @override
  String get archiveSecondaryCategoryDescription =>
      'This category will no longer be available for new transactions. Historical transactions are not affected.';

  @override
  String get categoryName => 'Category name';

  @override
  String get categoryNameNoSlash => 'Names cannot contain /';

  @override
  String get categoryNameInvalidOrDuplicate =>
      'Invalid name or another category at this level already uses it';

  @override
  String get calibrateBalanceAction => 'Calibrate balance';

  @override
  String insufficientBalance(String account, String amount) {
    return '$account has insufficient funds. Available: $amount';
  }

  @override
  String overpayment(String account, String amount) {
    return '$account has only $amount outstanding and cannot be reduced further';
  }

  @override
  String get fixedOtherCategory =>
      '“Other” is the required fallback for this primary category';

  @override
  String get otherCategoryRequired =>
      'Every primary category must keep an “Other” secondary category';

  @override
  String get editTransaction => 'Edit transaction';

  @override
  String get close => 'Close';

  @override
  String get amount => 'Amount';

  @override
  String get categoryLoadFailed => 'Could not load categories';

  @override
  String get accountLoadFailed => 'Could not load accounts';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get saveTransaction => 'Save transaction';

  @override
  String get expenseNoteHint => 'What was this money spent on?';

  @override
  String get incomeNoteHint => 'Where did this money come from?';

  @override
  String get transferNoteHint => 'For example: Alipay to WeChat Pay';

  @override
  String get borrowingNoteHint => 'For example: Loan from a friend';

  @override
  String get repaymentNoteHint => 'For example: Repay a friend';

  @override
  String get primaryCategory => 'Primary category';

  @override
  String get secondaryCategory => 'Secondary category';

  @override
  String get paymentAccount => 'Payment account';

  @override
  String get incomeDestinationAccount => 'Income destination account';

  @override
  String archivedName(String name) {
    return '$name (archived)';
  }

  @override
  String get quickAddLiability => 'Quick-add liability account';

  @override
  String get fundsDestinationAccount => 'Funds destination account';

  @override
  String get repaymentSourceAccount => 'Payment account';

  @override
  String get repaymentLiabilityAccount => 'Liability to repay';

  @override
  String get transferFromAccount => 'From account';

  @override
  String get transferToAccount => 'To account';

  @override
  String get addAvailableAccountFirst => 'Add an available account first';

  @override
  String liabilityName(String name) {
    return '$name (liability)';
  }

  @override
  String get selectRequiredAccountAndCategory =>
      'Select the required accounts and category';

  @override
  String get transactionChangesSaved => 'Changes saved';

  @override
  String get transactionSavedLocally => 'Transaction saved locally';

  @override
  String get saveLaterFailed => 'Could not save. Please try again later.';

  @override
  String confirmImportCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return 'Import $_temp0?';
  }

  @override
  String get jsonImportInstructions =>
      'Paste a single object, an array, or a schema_version 1 JSON batch. Amounts must be strings and categories use “Primary/Secondary”.';

  @override
  String get jsonCode => 'JSON code';

  @override
  String get importTemplateCopied => 'Import template copied';

  @override
  String get copyTemplate => 'Copy template';

  @override
  String get parseAndPreview => 'Parse & preview';

  @override
  String get loading => 'Loading…';

  @override
  String willCreateAccount(String kind, String name) {
    return 'Create $kind account: $name';
  }

  @override
  String get removeItem => 'Remove item';

  @override
  String get backToCode => 'Back to code';

  @override
  String get importing => 'Importing…';

  @override
  String confirmImportButton(int count) {
    return 'Import $count';
  }

  @override
  String importedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return 'Imported $_temp0';
  }

  @override
  String batchNotImportedReason(String reason) {
    return 'Nothing was imported: $reason';
  }

  @override
  String get batchNotImported =>
      'Nothing was imported. Review the content and try again.';

  @override
  String editTypedTransaction(String type) {
    return 'Edit $type transaction';
  }

  @override
  String get isoTimestamp => 'ISO 8601 timestamp';

  @override
  String get account => 'Account';

  @override
  String get targetAccount => 'Target account';

  @override
  String get category => 'Category';

  @override
  String get note => 'Note';

  @override
  String get invalidTimestamp => 'Invalid timestamp';

  @override
  String get accountKindElectronicWallet => 'Electronic wallet';

  @override
  String get accountKindEntrustedShort => 'Entrusted / authorized funds';

  @override
  String get reportReadFailed => 'Could not load reports';

  @override
  String get periodDay => 'Day';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get periodYear => 'Year';

  @override
  String get expenseCategories => 'Expense categories';

  @override
  String get noExpenseCategoryData =>
      'No expense category data for this period';

  @override
  String get incomeCategories => 'Income categories';

  @override
  String get noIncomeCategoryData => 'No income category data for this period';

  @override
  String get exportTransactions => 'Export transactions';

  @override
  String get incomeExpenseBalance => 'Income – expense';

  @override
  String get borrowingRepayment => 'Borrowing / repayment';

  @override
  String get expenseTrend => 'Expense trend';

  @override
  String get noExpensesThisPeriod => 'No expenses for this period';

  @override
  String get liabilityTrend => 'Liability trend';

  @override
  String closingAmount(String amount) {
    return 'Closing $amount';
  }

  @override
  String get noLiabilityData => 'No liability accounts or liability changes';

  @override
  String liabilityRangeSummary(String opening, String current) {
    return 'Opening $opening · Current total liabilities $current';
  }

  @override
  String get timeRange => 'Time range';

  @override
  String get thisWeek => 'This week';

  @override
  String get thisMonth => 'This month';

  @override
  String get thisYear => 'This year';

  @override
  String get allTime => 'All time';

  @override
  String get customRange => 'Custom range';

  @override
  String get fileFormat => 'File format';

  @override
  String get jsonFormatDescription => 'JSON (complete and re-importable)';

  @override
  String get csvFormatDescription => 'CSV (spreadsheet analysis)';

  @override
  String get markdownFormatDescription => 'Markdown (readable)';

  @override
  String get preparing => 'Preparing…';

  @override
  String get export => 'Export';

  @override
  String get transactionExportSubject => 'Summa transaction export';

  @override
  String get backupUnderYourControl =>
      'Your complete backups, under your control';

  @override
  String get backupLocationDescription =>
      'Local snapshots are stored in Summa\'s app-specific documents directory. Recent Android file managers may not show it directly, so manage or export snapshots here.';

  @override
  String get automaticBackups => 'Automatic backups';

  @override
  String get automaticBackupsSubtitle =>
      'Saved before the first successful change after each launch; the latest five snapshots are retained.';

  @override
  String get noAutomaticBackupYet =>
      'No successful changes have occurred during this launch';

  @override
  String get manualBackups => 'Manual backups';

  @override
  String get manualBackupsSubtitle =>
      'Local snapshots remain inside the app; exported backups can be saved to a file manager, cloud drive, or another location.';

  @override
  String get backupInsideApp => 'Back up inside the app';

  @override
  String get backupInsideAppSubtitle =>
      'Create a manual snapshot that is not limited by the five automatic slots';

  @override
  String get exportOrShareBackup => 'Export or share backup';

  @override
  String get exportOrShareBackupSubtitle =>
      'Create a complete Summa JSON backup and hand it to the system';

  @override
  String get restoreExternalBackup => 'Restore an external backup file';

  @override
  String get restoreExternalBackupSubtitle =>
      'Choose a JSON file, then replace or merge the ledger';

  @override
  String get noManualBackups => 'No manual local backups yet';

  @override
  String get reset => 'Reset';

  @override
  String get resetSubtitle =>
      'Resetting the ledger preserves local backups; factory reset deletes them as well.';

  @override
  String get resetTransactionsAccounts => 'Reset transactions & accounts';

  @override
  String get resetTransactionsAccountsSubtitle =>
      'Clear transactions, restore zero-balance default accounts, and preserve categories and backups';

  @override
  String get factoryReset => 'Factory reset';

  @override
  String get factoryResetSubtitle =>
      'Clear transactions, accounts, categories, and every local backup';

  @override
  String get cannotReadBackupDirectory =>
      'Could not read the local backup directory';

  @override
  String get manualBackupName => 'Manual backup name';

  @override
  String get myBackup => 'My backup';

  @override
  String get manualBackupSaved => 'Manual backup saved inside the app';

  @override
  String get createLocalBackupFailed => 'Could not create the local backup';

  @override
  String get completeBackupSubject => 'Summa complete backup';

  @override
  String get backupExportFailed =>
      'Could not export the backup. Please try again.';

  @override
  String get cannotReadSelectedBackup =>
      'Could not read the selected backup file';

  @override
  String get renameBackup => 'Rename backup';

  @override
  String get renameBackupFailed =>
      'Could not rename. Check whether a backup already uses that name.';

  @override
  String get deleteBackupTitle => 'Delete backup snapshot?';

  @override
  String deleteBackupMessage(String name) {
    return '“$name” will be permanently deleted. This cannot be undone.';
  }

  @override
  String get deleteBackupFailed => 'Could not delete the backup';

  @override
  String get backupNoLongerAvailable =>
      'The backup snapshot no longer exists or cannot be read';

  @override
  String get restoredSelectedBackup => 'Restored the selected backup';

  @override
  String get backupMerged => 'Backup merged';

  @override
  String get restoreDatabaseSafeFailure =>
      'Restore failed; the database was not partially changed';

  @override
  String get confirmRestoreContents => 'Confirm restore contents';

  @override
  String get merge => 'Merge';

  @override
  String get replaceAndRestore => 'Replace & restore';

  @override
  String get restoreThisSnapshotTitle => 'Restore this snapshot?';

  @override
  String get mergeThisSnapshotTitle => 'Merge this snapshot?';

  @override
  String get confirmRestore => 'Confirm restore';

  @override
  String get confirmMerge => 'Confirm merge';

  @override
  String get resetTransactionsAccountsTitle => 'Reset transactions & accounts?';

  @override
  String get resetTransactionsAccountsMessage =>
      'All transactions will be permanently cleared, custom accounts deleted, and default account balances set to zero. Categories and all backups will be preserved.';

  @override
  String get confirmReset => 'Confirm reset';

  @override
  String get transactionsAccountsReset =>
      'Transactions and accounts reset; all backups were preserved';

  @override
  String get resetSafeFailure =>
      'Reset failed; the data was not partially changed';

  @override
  String get factoryResetTitle => 'Factory reset?';

  @override
  String get factoryResetMessage =>
      'Transactions, accounts, categories, and every in-app backup will be permanently cleared. Files exported outside the app are not affected.';

  @override
  String get clearEverything => 'Clear everything';

  @override
  String get factoryResetComplete => 'Summa was reset to factory defaults';

  @override
  String get factoryResetFailed => 'Factory reset failed';

  @override
  String get tapToRestore => 'Tap to restore';

  @override
  String get mergeIntoLedger => 'Merge into current ledger';

  @override
  String backupTime(String time) {
    return 'Backup time: $time';
  }

  @override
  String backupAccountCount(int count) {
    return 'Accounts: $count';
  }

  @override
  String backupCategoryCount(int count) {
    return 'Categories: $count';
  }

  @override
  String backupTransactionCount(int count, int deleted) {
    return 'Transactions: $count ($deleted deleted)';
  }

  @override
  String get restoreSafetyHint =>
      'Before applying the operation, Summa protects the current state according to this launch\'s automatic-backup rule.';

  @override
  String get automaticBackupName => 'Automatic backup';

  @override
  String backupInvalidJson(String details) {
    return 'Invalid backup JSON: $details';
  }

  @override
  String get backupUnsupported =>
      'This is not a supported Summa complete backup';

  @override
  String get backupInvalidTime => 'The backup timestamp is invalid';

  @override
  String backupMissingList(String field) {
    return 'The backup is missing the $field list';
  }

  @override
  String backupInvalidItem(String field) {
    return '$field contains an invalid item';
  }

  @override
  String backupFieldMustString(String field) {
    return 'Field $field must be a string';
  }

  @override
  String backupFieldMustNullableString(String field) {
    return 'Field $field must be a string or null';
  }

  @override
  String backupFieldMustInteger(String field) {
    return 'Field $field must be an integer';
  }

  @override
  String backupFieldMustBoolean(String field) {
    return 'Field $field must be a boolean';
  }

  @override
  String backupFieldInvalidTime(String field) {
    return 'Field $field is not a valid timestamp';
  }

  @override
  String backupFieldUnsupportedValue(String field, String value) {
    return 'Field $field has an unsupported value: $value';
  }
}
