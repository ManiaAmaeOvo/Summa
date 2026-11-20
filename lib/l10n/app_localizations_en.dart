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
  String get fontSize => 'Font size';

  @override
  String get fontSizeSubtitle => 'Adjust text size throughout Summa';

  @override
  String get fontSizeSystem => 'Follow system';

  @override
  String get fontSizeSmall => 'Small';

  @override
  String get fontSizeStandard => 'Standard';

  @override
  String get fontSizeLarge => 'Large';

  @override
  String get fontSizeExtraLarge => 'Extra large';

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
      'Clear transactions and account-linked plans, then restore zero-balance default accounts';

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
      'All transactions, recurring plans, and account-linked budgets and allowances will be cleared. Custom accounts will be deleted and default balances set to zero. Categories, other budgets, and backups will be preserved.';

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

  @override
  String get pendingPosting => 'Pending';

  @override
  String get saveAsPending => 'Save as pending';

  @override
  String get pendingPostingHint =>
      'Pending transactions stay outside balances and reports until posted.';

  @override
  String get postTransactionAction => 'Confirm posting';

  @override
  String get transactionPosted => 'Transaction posted';

  @override
  String get addPaymentAccount => 'Add payment account';

  @override
  String get extraPaymentAmount => 'Amount from this account';

  @override
  String get removePaymentAccount => 'Remove payment account';

  @override
  String get mainPaymentRemainder =>
      'The first account pays the remaining amount.';

  @override
  String get invalidPaymentSplit =>
      'Use distinct accounts with positive amounts that add up to the transaction total.';

  @override
  String get recordRefund => 'Record refund';

  @override
  String get editRefund => 'Edit refund';

  @override
  String get refund => 'Refund';

  @override
  String refundAvailable(String amount) {
    return 'Available to refund: $amount';
  }

  @override
  String get refundRecorded => 'Refund saved';

  @override
  String refundLimitExceeded(String amount) {
    return 'The refund cannot exceed the remaining $amount for this account.';
  }

  @override
  String get linkedRefunds =>
      'Remove the linked refunds before editing or deleting the original purchase.';

  @override
  String get archivedPostingAccount =>
      'An account is archived. Restore it or choose another account before posting.';

  @override
  String get backupLedgerConflict =>
      'This backup conflicts with the current ledger or contains invalid postings or refunds.';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get summaryCurrency => 'Summary currency';

  @override
  String invalidCurrencyAmount(String currency) {
    return 'Enter an amount valid for $currency.';
  }

  @override
  String get transferSettlementAmount => 'Amount received';

  @override
  String get quotedExchangeRate => 'Quoted rate (optional)';

  @override
  String exchangeRateDirection(String target, String source) {
    return '$target per 1 $source';
  }

  @override
  String effectiveExchangeRateLabel(String source, String rate, String target) {
    return 'Effective rate: 1 $source = $rate $target';
  }

  @override
  String quotedExchangeRateLabel(String source, String rate, String target) {
    return 'Quoted rate: 1 $source = $rate $target';
  }

  @override
  String get invalidQuotedExchangeRate =>
      'Enter a positive decimal rate with up to 18 decimal places.';

  @override
  String get invalidTransferSettlement =>
      'A transfer between different currencies requires the actual amount received. Other transaction types require matching currencies.';

  @override
  String get currencyMismatch =>
      'Choose accounts in the transaction’s currency.';

  @override
  String get legacyTransferConflict =>
      'The old backup would overwrite an existing cross-currency transfer.';

  @override
  String get estimatedNetWorth => 'Estimated net worth';

  @override
  String get valuationSettings => 'Valuation settings';

  @override
  String get valuationBaseCurrency => 'Base currency for valuation';

  @override
  String valuationBaseDescription(String currency) {
    return 'Valued in $currency';
  }

  @override
  String missingValuationRates(String currencies) {
    return 'Add rates to value: $currencies';
  }

  @override
  String unsupportedValuationCurrencies(String currencies) {
    return 'Currency precision unavailable: $currencies';
  }

  @override
  String get valuationReadFailed => 'Could not load valuation settings.';

  @override
  String get valuationSettingsHint =>
      'These rates value today’s account balances. Each transfer shows its historical settlement rate in the transaction details.';

  @override
  String get valuationRatesTitle => 'Manual valuation rates';

  @override
  String get noValuationCurrencies =>
      'The current accounts use the selected base currency.';

  @override
  String get valuationRateMissing => 'Rate required';

  @override
  String valuationRateAsOf(String date) {
    return 'Updated $date';
  }

  @override
  String valuationRatePair(String source, String base) {
    return '$source → $base';
  }

  @override
  String get editValuationRate => 'Edit valuation rate';

  @override
  String get valuationRateField => 'Valuation rate';

  @override
  String get invalidValuationRate =>
      'Enter a positive decimal rate with up to 18 decimal places.';

  @override
  String get removeValuationRate => 'Remove rate';

  @override
  String get invalidBackupValuation =>
      'The backup contains invalid or duplicate valuation settings.';

  @override
  String get familyDirectFunding => 'Paid directly by family';

  @override
  String get familyDirectExplanation =>
      'Records the purchase against family funding.';

  @override
  String get lending => 'Lend';

  @override
  String get advance => 'Pay for someone';

  @override
  String get collection => 'Collect principal';

  @override
  String get reimbursement => 'Receive reimbursement';

  @override
  String get receivableAccount => 'Receivable account';

  @override
  String get accountKindReceivable => 'Receivable';

  @override
  String get accountKindThirdPartyPayable => 'Third-party payment due';

  @override
  String get receivableAccounts => 'Receivables';

  @override
  String get receivableAccountsDescription =>
      'Outstanding principal from loans and payments made for others.';

  @override
  String get quickAddReceivable => 'Add a receivable account';

  @override
  String get receivableBalanceExceeded =>
      'This change would make the outstanding receivable negative on its transaction date.';

  @override
  String get grossSpending => 'Total spending';

  @override
  String get personalSpending => 'Personally borne';

  @override
  String get entrustedSpending => 'Paid from entrusted funds';

  @override
  String get thirdPartyPayableSpending => 'Of personally borne, paid by others';

  @override
  String get unclassifiedSpending => 'Funding to review';

  @override
  String get familySupportReceived => 'Family money received';

  @override
  String get fundingAndCashFlow => 'Funding and personal cash flow';

  @override
  String get personalCashInflow => 'Personal cash inflow';

  @override
  String get personalCashOutflow => 'Personal cash outflow';

  @override
  String get personalCashFlowNet => 'Net personal cash flow';

  @override
  String get advancedFundingBackupError =>
      'The backup conflicts with funding or receivable records.';

  @override
  String get transactionDetails => 'Transaction details';

  @override
  String get foreignPurchase => 'Purchase priced in another currency';

  @override
  String get originalPrice => 'Original purchase amount';

  @override
  String get originalCurrency => 'Original currency';

  @override
  String get settledPurchaseAmount => 'Amount charged to payment account';

  @override
  String get splitCategories => 'Add category split';

  @override
  String get additionalCategory => 'Additional category';

  @override
  String get categoryShare => 'Category amount';

  @override
  String get advanceForOthers => 'Part of this bill is owed by someone else';

  @override
  String get advanceShare => 'Amount advanced for someone else';

  @override
  String get feeAmount => 'Fee';

  @override
  String get interestAmount => 'Interest';

  @override
  String get externalDebtPayment => 'Someone else paid this debt directly';

  @override
  String get externalDebtPaymentHint =>
      'Use for principal you do not owe back to the payer.';

  @override
  String get balanceAdjustment => 'Balance adjustment';

  @override
  String get balanceAdjustmentHint =>
      'The difference will be saved as a balance adjustment.';

  @override
  String get reverseTransaction => 'Reverse posting';

  @override
  String get confirmReversal =>
      'Save an opposite entry dated today and keep both entries in history?';

  @override
  String get postedReversal => 'Reversal saved';

  @override
  String get reversedPosting => 'Reversed';

  @override
  String get reversalPosting => 'Reversal';

  @override
  String get linkedReversal =>
      'This entry belongs to a reversal and its original. Both are kept in history.';

  @override
  String get invalidTransactionDetails =>
      'Check the accounts, amounts, and categories for this entry.';

  @override
  String get fundingReviewFilter => 'Only entries needing review';

  @override
  String get fundingReviewBadge => 'Needs review';

  @override
  String get fundingReviewHint =>
      'This historical entry has ambiguous accounting details. Review the original receipt and save a correction when the details are known.';

  @override
  String get financialChargesCategory => 'Financial charges';

  @override
  String get refundAdvanceShare => 'Reduce receivable by';

  @override
  String get refundAdvanceHint =>
      'Optional. If blank, the refund reduces spending first, then outstanding receivables.';

  @override
  String get accountKindSavings => 'Savings account';

  @override
  String get accountKindPrepaid => 'Prepaid balance';

  @override
  String get prepaidAccounts => 'Prepaid accounts';

  @override
  String get prepaidAccountsDescription =>
      'Stored value available for future purchases. Excluded from liquid assets.';

  @override
  String get reconciliation => 'Reconcile account';

  @override
  String get recordCheckpoint => 'Record checkpoint';

  @override
  String get checkpointDetails => 'Checkpoint details';

  @override
  String get checkpointTime => 'Observed at';

  @override
  String get observedBalance => 'Observed balance';

  @override
  String get noCheckpoints =>
      'There are no balance checkpoints for this account.';

  @override
  String get noSuccessfulReconciliation => 'No balanced checkpoint yet';

  @override
  String lastSuccessfulReconciliation(String date) {
    return 'Last balanced checkpoint $date';
  }

  @override
  String get checkpointBalanced => 'Balanced';

  @override
  String get checkpointUnbalanced => 'Difference to review';

  @override
  String get checkpointDifference => 'Difference (observed minus book)';

  @override
  String get bookBalanceAtCheckpoint => 'Book balance at this time';

  @override
  String get recordedBookBalance => 'Book balance when recorded';

  @override
  String get voidedCheckpoint => 'Voided';

  @override
  String get voidCheckpoint => 'Void checkpoint';

  @override
  String get confirmVoidCheckpoint =>
      'Void this observation? It will remain in the account history.';

  @override
  String get confirmVoidAdjustedCheckpoint =>
      'Void this observation and undo its linked balance adjustment? Both records will be kept in the audit history.';

  @override
  String get applyCheckpointAdjustment => 'Post difference as adjustment';

  @override
  String get confirmCheckpointAdjustment =>
      'Post an adjustment at the observed time using the displayed difference?';

  @override
  String get linkedAdjustmentRecorded =>
      'This checkpoint has a linked balance adjustment.';

  @override
  String get linkedCheckpoint =>
      'Void the linked checkpoint to undo this adjustment.';

  @override
  String get checkpointUnavailable =>
      'The checkpoint or account is unavailable. Check that the date is in the past and the account is active.';

  @override
  String get checkpointChanged =>
      'The book balance changed. Review the new difference and confirm again.';

  @override
  String get reconciliationCandidates => 'Transactions to review';

  @override
  String checkpointRange(String start, String end) {
    return 'After $start through $end';
  }

  @override
  String checkpointRangeThrough(String end) {
    return 'Through $end';
  }

  @override
  String get checkpointMatchingAmount => 'Could account for the difference';

  @override
  String get similarCheckpointMovement => 'Similar transaction in this period';

  @override
  String get noReconciliationCandidates =>
      'No transactions in this interval. Check for missing entries.';

  @override
  String get checkpointCandidateLimit => 'Showing the first 12 candidates.';

  @override
  String backupCheckpointCount(int count) {
    return 'Balance checkpoints $count';
  }

  @override
  String get checkpointBackupConflict =>
      'The backup has invalid or conflicting balance checkpoints.';

  @override
  String get csvImport => 'CSV import';

  @override
  String get csvHistory => 'Import batches';

  @override
  String get csvInstructions =>
      'Choose a generic CSV or a WeChat Pay or Alipay CSV/XLSX statement. Review the rows before posting.';

  @override
  String get csvChooseFile => 'Choose statement file';

  @override
  String get csvPaste => 'Paste CSV';

  @override
  String get csvPastedFile => 'Pasted CSV';

  @override
  String csvReviewSummary(int total, int selected) {
    return '$total rows · $selected selected';
  }

  @override
  String csvCommit(int count) {
    return 'Confirm $count selected';
  }

  @override
  String get csvChangeFile => 'Change input';

  @override
  String get csvRefresh => 'Refresh review';

  @override
  String csvLine(int line) {
    return 'Line $line';
  }

  @override
  String get csvReady => 'Ready to import';

  @override
  String get csvUnresolved => 'Choose account or category';

  @override
  String get csvSimilar => 'Possible match';

  @override
  String get csvDuplicate => 'Already imported or repeated in file';

  @override
  String get csvSourceConflict => 'Same source and ID with conflicting values';

  @override
  String get csvInvalid => 'Invalid row';

  @override
  String get csvLinkedRow => 'Matched to existing transaction';

  @override
  String get csvCreatedRow => 'Created transaction';

  @override
  String get csvSeparateRow => 'Approved as a distinct transaction';

  @override
  String get csvSourceAccount => 'Posting account';

  @override
  String get csvTargetAccount => 'Destination account';

  @override
  String get csvNoEligibleAccounts =>
      'Create a compatible account in Accounts, then return to review.';

  @override
  String get csvReviewMapping => 'Check assignment';

  @override
  String get csvSimilarHint =>
      'Tap an existing transaction to link it. If this row represents a separate payment, approve it as a new entry.';

  @override
  String get csvEarlierSource => 'Also seen in an earlier batch';

  @override
  String get csvCategoryForNew =>
      'Choose a category before posting a new entry.';

  @override
  String get csvSkipRow => 'Skip row';

  @override
  String get csvChangeMapping => 'Change assignment';

  @override
  String get csvAddSeparately => 'Post as separate entry';

  @override
  String csvBatchCounts(int added, int matched) {
    return '$added added · $matched matched';
  }

  @override
  String get csvNoHistory => 'No CSV import batches yet.';

  @override
  String get csvBatchDetails => 'Import batch details';

  @override
  String get csvUndone => 'Undone';

  @override
  String get csvUndo => 'Undo batch';

  @override
  String get csvConfirmUndo =>
      'Remove the transactions created by this batch? Matched transactions will remain in the ledger.';

  @override
  String get csvOriginalRow => 'Original CSV row';

  @override
  String get csvLedgerId => 'Ledger transaction ID';

  @override
  String get csvEncoding => 'Save the file as UTF-8 CSV.';

  @override
  String get csvTooLarge => 'Use a file of up to 2 MB and 500 data rows.';

  @override
  String get csvEmpty => 'No data rows were found.';

  @override
  String get csvHeaders =>
      'Use unique headers including type, amount, occurred_at, and account.';

  @override
  String get csvSyntax => 'Check the quotation marks in the CSV.';

  @override
  String get csvColumns => 'The column count differs from the header.';

  @override
  String get csvTypeInvalid =>
      'Use expense, income, transfer, borrowing, or repayment.';

  @override
  String get csvAmountInvalid =>
      'Use a positive decimal amount with the currency’s supported precision.';

  @override
  String get csvDateInvalid => 'Use a valid ISO 8601 date or date and time.';

  @override
  String get csvCurrencyInvalid => 'This currency is unsupported.';

  @override
  String get csvSourceRequired => 'Provide a source for each external ID.';

  @override
  String get csvAdvanced =>
      'Use a complete backup for advanced transaction details.';

  @override
  String get csvReviewChanged =>
      'The ledger or selection changed. Refresh and review the affected rows.';

  @override
  String get csvUndoModified =>
      'A transaction in this batch was edited or deleted. The batch was kept intact.';

  @override
  String get csvUndoLinked =>
      'A transaction is linked to a refund, reversal, another batch, a repayment, or funds later used. The batch was kept intact.';

  @override
  String get csvBatchUnavailable => 'This batch is unavailable.';

  @override
  String get csvOperationFailed => 'The CSV operation failed.';

  @override
  String get csvBackupConflict =>
      'The backup contains invalid or conflicting CSV import batches.';

  @override
  String backupImportBatchCount(int count) {
    return 'CSV import batches $count';
  }

  @override
  String get importCategoryRules => 'Import category rules';

  @override
  String get importRuleInstructions =>
      'Suggest categories from keywords. Review suggestions before posting.';

  @override
  String get importRuleEmpty =>
      'No rules yet. Add a keyword and choose a category.';

  @override
  String get importRuleAdd => 'Add rule';

  @override
  String get importRuleEdit => 'Edit rule';

  @override
  String get importRuleDelete => 'Delete this rule?';

  @override
  String get importRuleFieldLabel => 'Match field';

  @override
  String get importRuleKeyword => 'Contains keyword';

  @override
  String get importRulePriority => 'Priority';

  @override
  String get importRulePriorityHint => 'Smaller numbers take priority.';

  @override
  String importRulePriorityValue(int value) {
    return 'Priority $value';
  }

  @override
  String get importRuleEnabled => 'Enabled';

  @override
  String get importRuleDisabled => 'Disabled';

  @override
  String get importRuleInvalid =>
      'Enter a keyword and a priority between 0 and 9999.';

  @override
  String get importRuleUnavailable => 'Category unavailable';

  @override
  String get importRuleMerchant => 'Merchant or counterparty';

  @override
  String get importRuleDescription => 'Description or note';

  @override
  String get importRulePayment => 'Payment channel';

  @override
  String get importRuleSource => 'Source';

  @override
  String importRuleSuggested(String keyword) {
    return 'Suggested by rule “$keyword”';
  }

  @override
  String get importRuleConflict => 'Rules disagree. Choose a category.';

  @override
  String get importRulesBackupConflict =>
      'The backup has invalid or conflicting import rules.';

  @override
  String get statementSkipped =>
      'Review the platform status and type. This row cannot be posted as ordinary income or spending.';

  @override
  String get statementWorkbookInvalid =>
      'Use an unencrypted XLSX workbook with one supported statement sheet.';

  @override
  String get csvCopyScreenshotPrompt => 'Copy screenshot transcription prompt';

  @override
  String get csvScreenshotPromptCopied =>
      'Screenshot transcription prompt copied';

  @override
  String get csvScreenshotPrompt =>
      'Transcribe only clearly visible completed income and expense entries from my screenshots. Return CSV only, without a Markdown fence. Use this header verbatim:\ntype,amount,occurred_at,account,category,note,currency_code,merchant,description,payment_channel,source,external_id\nUse expense or income, a positive amount, and an ISO 8601 date or timestamp. Leave unknown fields blank. Do not infer dates, totals, or transaction IDs. Only include an external ID if the screenshot shows the actual transaction ID and its source. Keep refunds, transfers, repayments, and pending items separate from ordinary income and expenses. Omit names of private individuals, account numbers, and card numbers. Quote fields containing commas, double quotes, or line breaks and escape double quotes by doubling them.';

  @override
  String get spendingPlanBackupConflict =>
      'The backup has invalid or conflicting budgets or allowances.';

  @override
  String get spendingPlans => 'Budgets & allowances';

  @override
  String get addBudget => 'Add budget';

  @override
  String get addAllowance => 'Add allowance';

  @override
  String get spendingPlansEmpty =>
      'Create a budget or track an allowance for an entrusted account.';

  @override
  String get spendingPlansLoadFailed =>
      'Could not load budgets and allowances.';

  @override
  String get spendingPlanScope => 'Spending scope';

  @override
  String get spendingPlanAllowance => 'External allowance';

  @override
  String get spendingPlanNoAccounts => 'No eligible account is available.';

  @override
  String get spendingPlanNoCategories => 'No expense category is available.';

  @override
  String get spendingPlanMonthly => 'Monthly';

  @override
  String get spendingPlanFixedPeriod => 'Fixed date range';

  @override
  String get spendingPlanStart => 'First day';

  @override
  String get spendingPlanEnd => 'Last day';

  @override
  String get spendingPlanMonthlyHint =>
      'Each month resets on the first cycle’s day, or the last day of a shorter month.';

  @override
  String get spendingPlanRollover => 'Carry over unused amount';

  @override
  String get spendingPlanLimit => 'Period limit';

  @override
  String get spendingPlanCarried => 'Carried over';

  @override
  String get spendingPlanUsed => 'Used';

  @override
  String get spendingPlanRemaining => 'Remaining';

  @override
  String get spendingPlanProjected => 'Projected spending at current pace';

  @override
  String get spendingPlanOverLimit => 'Over limit';

  @override
  String get spendingPlanChangeLimit => 'Change period limit';

  @override
  String get spendingPlanOngoing => 'Apply to this and later months';

  @override
  String get spendingPlanLimitHistory => 'Limit changes';

  @override
  String get spendingPlanSinglePeriod => 'This period only';

  @override
  String get spendingPlanFromPeriod => 'This period onward';

  @override
  String get spendingPlanPrevious => 'Previous period';

  @override
  String get spendingPlanNext => 'Next period';

  @override
  String get spendingPlanNoActivity => 'No posted spending in this period.';

  @override
  String get spendingPlanArchived => 'Archived';

  @override
  String get spendingPlanReactivate => 'Reactivate';

  @override
  String get spendingPlanInvalid =>
      'Check the dates, amount, and selected category or account. An entrusted account can have one active allowance.';

  @override
  String backupSpendingPlanCount(int count) {
    return 'Budgets & allowances $count';
  }

  @override
  String get recurringPlans => 'Subscriptions & recurring plans';

  @override
  String get recurringAddPlan => 'Add recurring plan';

  @override
  String get recurringEmpty =>
      'Create a subscription or another repeating expense or income.';

  @override
  String get recurringLoadFailed => 'Could not load recurring plans.';

  @override
  String get recurringSubscription => 'Subscription';

  @override
  String get recurringPlanType => 'Plan type';

  @override
  String get recurringCadence => 'Frequency';

  @override
  String get recurringDaily => 'Daily';

  @override
  String get recurringWeekly => 'Weekly';

  @override
  String get recurringQuarterly => 'Quarterly';

  @override
  String get recurringYearly => 'Yearly';

  @override
  String get recurringCustom => 'Custom days';

  @override
  String get recurringIntervalDays => 'Days between occurrences';

  @override
  String get recurringFirstDue => 'First due date';

  @override
  String get recurringNextDue => 'Next due date';

  @override
  String get recurringExpectedAmount => 'Expected amount';

  @override
  String get recurringChangeAmount => 'Change expected amount';

  @override
  String get recurringPause => 'Pause';

  @override
  String get recurringResume => 'Resume';

  @override
  String get recurringPaused => 'Paused';

  @override
  String get recurringOverdue => 'Overdue';

  @override
  String get recurringScheduleEnded => 'No more dates';

  @override
  String get recurringConfirmPosting => 'Review & post';

  @override
  String get recurringPostTitle => 'Confirm actual transaction';

  @override
  String get recurringActualAmount => 'Actual amount';

  @override
  String get recurringActualDate => 'Actual date';

  @override
  String get recurringPost => 'Confirm & post';

  @override
  String get recurringLink => 'Link an existing transaction';

  @override
  String get recurringSearch => 'Search note, date or amount';

  @override
  String get recurringNoMatches =>
      'No eligible posted transactions for this account and currency.';

  @override
  String get recurringHistory => 'Linked transactions';

  @override
  String get recurringNoHistory => 'No cycles have been confirmed yet.';

  @override
  String get recurringUnavailableEntry => 'Transaction unavailable';

  @override
  String get recurringReversedEntry => 'Reversed';

  @override
  String get recurringChangedEntry => 'Transaction details changed';

  @override
  String get recurringUnavailableTarget =>
      'The account or category is archived or unavailable.';

  @override
  String get recurringInvalid => 'Check the plan, amount and date.';

  @override
  String get recurringStale =>
      'This cycle was already processed or the plan changed. Review the current cycle.';

  @override
  String get recurringIneligible => 'This transaction can no longer be linked.';

  @override
  String get recurringAlreadyLinked =>
      'This transaction is already linked to a cycle.';

  @override
  String get recurringBackupConflict =>
      'The backup has invalid or conflicting recurring plans or transaction links.';

  @override
  String backupRecurringPlanCount(int count) {
    return 'Subscriptions & recurring plans $count';
  }
}
