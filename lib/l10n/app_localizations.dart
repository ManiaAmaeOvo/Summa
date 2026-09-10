import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Summa'**
  String get appName;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @ledger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get ledger;

  /// No description provided for @app.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get app;

  /// No description provided for @categoryManagement.
  ///
  /// In en, this message translates to:
  /// **'Category management'**
  String get categoryManagement;

  /// No description provided for @categoryManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage two-level income and expense categories'**
  String get categoryManagementSubtitle;

  /// No description provided for @dataAndBackup.
  ///
  /// In en, this message translates to:
  /// **'Data & backup'**
  String get dataAndBackup;

  /// No description provided for @dataAndBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local snapshots, export, restore, and reset'**
  String get dataAndBackupSubtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used by Summa'**
  String get languageSubtitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSimplifiedChinese.
  ///
  /// In en, this message translates to:
  /// **'Simplified Chinese'**
  String get languageSimplifiedChinese;

  /// No description provided for @userGuide.
  ///
  /// In en, this message translates to:
  /// **'User guide'**
  String get userGuide;

  /// No description provided for @userGuideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Features, instructions, and data safety'**
  String get userGuideSubtitle;

  /// No description provided for @aboutSumma.
  ///
  /// In en, this message translates to:
  /// **'About Summa'**
  String get aboutSumma;

  /// No description provided for @aboutSummaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Version, overview, and developer information'**
  String get aboutSummaSubtitle;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({buildNumber})'**
  String versionLabel(String version, String buildNumber);

  /// No description provided for @readingVersion.
  ///
  /// In en, this message translates to:
  /// **'Reading version information…'**
  String get readingVersion;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'A completely local-first personal ledger. Accounts, liabilities, categories, and transactions stay on your device by default, with no sign-in or backend server required.'**
  String get aboutDescription;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @builtWith.
  ///
  /// In en, this message translates to:
  /// **'Built with'**
  String get builtWith;

  /// No description provided for @dataPrinciples.
  ///
  /// In en, this message translates to:
  /// **'Data principles'**
  String get dataPrinciples;

  /// No description provided for @dataPrinciplesValue.
  ///
  /// In en, this message translates to:
  /// **'Local storage, explicit export, user-controlled'**
  String get dataPrinciplesValue;

  /// No description provided for @softwareLicense.
  ///
  /// In en, this message translates to:
  /// **'Software license'**
  String get softwareLicense;

  /// No description provided for @softwareLicenseValue.
  ///
  /// In en, this message translates to:
  /// **'PolyForm Noncommercial 1.0.0 · Noncommercial use only'**
  String get softwareLicenseValue;

  /// No description provided for @cannotOpenGitHub.
  ///
  /// In en, this message translates to:
  /// **'Could not open the GitHub profile'**
  String get cannotOpenGitHub;

  /// No description provided for @helpIntro.
  ///
  /// In en, this message translates to:
  /// **'Summa works entirely locally. Start by calibrating account balances, review your categories, and then begin recording transactions. Export a complete backup regularly for important data.'**
  String get helpIntro;

  /// No description provided for @helpTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions and types'**
  String get helpTransactionsTitle;

  /// No description provided for @helpTransactions1.
  ///
  /// In en, this message translates to:
  /// **'Tap “Add transaction” on the home screen to record an expense, income, borrowing, repayment, or transfer between personal accounts. The current time is selected by default and can be changed.'**
  String get helpTransactions1;

  /// No description provided for @helpTransactions2.
  ///
  /// In en, this message translates to:
  /// **'Borrowing increases both a liability and the destination account balance and is not income. Repayment reduces both the payment balance and the liability and is not an expense. Transfers are excluded from income and expense totals.'**
  String get helpTransactions2;

  /// No description provided for @helpTransactions3.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balances, overpayment, and invalid account flows are rejected. Tap an existing transaction to edit or soft-delete it.'**
  String get helpTransactions3;

  /// No description provided for @helpAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts and categories'**
  String get helpAccountsTitle;

  /// No description provided for @helpAccounts1.
  ///
  /// In en, this message translates to:
  /// **'The Accounts tab shows personal liquid assets, outstanding liabilities, liquid net worth, and entrusted or authorized funds. Tap an account to calibrate its current balance; calibration does not create artificial income or expenses.'**
  String get helpAccounts1;

  /// No description provided for @helpAccounts2.
  ///
  /// In en, this message translates to:
  /// **'Accounts can be added or archived. Category management in Settings maintains separate two-level structures for income and expenses. Transactions use the second level, and every primary category keeps an “Other” fallback.'**
  String get helpAccounts2;

  /// No description provided for @helpJsonTitle.
  ///
  /// In en, this message translates to:
  /// **'JSON code import'**
  String get helpJsonTitle;

  /// No description provided for @helpJson1.
  ///
  /// In en, this message translates to:
  /// **'Use the code icon in the top-right of the home screen to paste one or many JSON transactions. This is useful after an OCR tool or language model structures a statement screenshot.'**
  String get helpJson1;

  /// No description provided for @helpJson2.
  ///
  /// In en, this message translates to:
  /// **'The flow is parse and validate, preview and edit each item, confirm the count, then write atomically. Unknown accounts can be created automatically; unknown categories must be created first or corrected in the preview.'**
  String get helpJson2;

  /// No description provided for @helpJson3.
  ///
  /// In en, this message translates to:
  /// **'Amounts are positive decimal strings, timestamps use ISO 8601, and categories use “Primary/Secondary”.'**
  String get helpJson3;

  /// No description provided for @helpReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports and export'**
  String get helpReportsTitle;

  /// No description provided for @helpReports1.
  ///
  /// In en, this message translates to:
  /// **'Reports supports daily, weekly, monthly, and yearly views with income and expense category charts, expense trends, and liability trends.'**
  String get helpReports1;

  /// No description provided for @helpReports2.
  ///
  /// In en, this message translates to:
  /// **'Export transactions for this week, month, year, all time, or a custom range as JSON, CSV, or Markdown. Transaction exports are for analysis and are not complete restorable backups.'**
  String get helpReports2;

  /// No description provided for @helpBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup, merge, and restore'**
  String get helpBackupTitle;

  /// No description provided for @helpBackup1.
  ///
  /// In en, this message translates to:
  /// **'Before the first successful change after each launch, Summa automatically saves the complete previous state. Up to five automatic snapshots are kept, and failed operations do not consume a slot.'**
  String get helpBackup1;

  /// No description provided for @helpBackup2.
  ///
  /// In en, this message translates to:
  /// **'Manual backups can be saved inside the app or exported externally. Tap a local snapshot to preview and replace the ledger, or use its menu to merge, rename a manual snapshot, or delete it.'**
  String get helpBackup2;

  /// No description provided for @helpBackup3.
  ///
  /// In en, this message translates to:
  /// **'In-app snapshots live in the app-specific directory shown in Settings and are removed when the app is uninstalled or factory-reset. Use export or share for long-term storage.'**
  String get helpBackup3;

  /// No description provided for @helpResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset scope'**
  String get helpResetTitle;

  /// No description provided for @helpReset1.
  ///
  /// In en, this message translates to:
  /// **'“Reset transactions & accounts” clears transactions and custom accounts and sets default accounts to zero, while preserving categories and backups.'**
  String get helpReset1;

  /// No description provided for @helpReset2.
  ///
  /// In en, this message translates to:
  /// **'“Factory reset” also restores default categories and deletes every in-app backup. Externally exported files are not affected.'**
  String get helpReset2;

  /// No description provided for @helpSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Data safety'**
  String get helpSecurityTitle;

  /// No description provided for @helpSecurity1.
  ///
  /// In en, this message translates to:
  /// **'The ledger stays on this device by default. Uninstalling normally removes the database and local snapshots, so export a complete backup before uninstalling or changing devices.'**
  String get helpSecurity1;

  /// No description provided for @helpSecurity2.
  ///
  /// In en, this message translates to:
  /// **'Complete backups contain sensitive financial information. Store them only in trusted locations and never upload a real backup to a public issue.'**
  String get helpSecurity2;

  /// No description provided for @accountBalances.
  ///
  /// In en, this message translates to:
  /// **'Account balances'**
  String get accountBalances;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @codeImport.
  ///
  /// In en, this message translates to:
  /// **'JSON import'**
  String get codeImport;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get addTransaction;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @expenseThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Expense this month'**
  String get expenseThisMonth;

  /// No description provided for @expenseThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Expense this week'**
  String get expenseThisWeek;

  /// No description provided for @expenseAllTime.
  ///
  /// In en, this message translates to:
  /// **'All-time expense'**
  String get expenseAllTime;

  /// No description provided for @liquidNetWorth.
  ///
  /// In en, this message translates to:
  /// **'Liquid net worth'**
  String get liquidNetWorth;

  /// No description provided for @transactionActions.
  ///
  /// In en, this message translates to:
  /// **'Transaction actions'**
  String get transactionActions;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirmDeleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Delete this transaction?'**
  String get confirmDeleteTransaction;

  /// No description provided for @deleteRecalculatesBalances.
  ///
  /// In en, this message translates to:
  /// **'Related account balances will be recalculated after deletion.'**
  String get deleteRecalculatesBalances;

  /// No description provided for @transactionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get transactionDeleted;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete. Please try again.'**
  String get deleteFailed;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @borrowing.
  ///
  /// In en, this message translates to:
  /// **'Borrowing'**
  String get borrowing;

  /// No description provided for @repayment.
  ///
  /// In en, this message translates to:
  /// **'Repayment'**
  String get repayment;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @creditedTo.
  ///
  /// In en, this message translates to:
  /// **'Credited to {account}'**
  String creditedTo(String account);

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactions;

  /// No description provided for @noTransactionsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap “Add transaction” to create your first local record.'**
  String get noTransactionsHint;

  /// No description provided for @ledgerReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the ledger'**
  String get ledgerReadFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @accountBalanceReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load account balances'**
  String get accountBalanceReadFailed;

  /// No description provided for @archiveAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive {account}?'**
  String archiveAccountTitle(String account);

  /// No description provided for @archiveAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'The account will be removed from selection lists and balance totals, while historical transactions remain available. A default account can later be re-enabled with “Restore defaults”.'**
  String get archiveAccountDescription;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @accountArchived.
  ///
  /// In en, this message translates to:
  /// **'{account} archived'**
  String accountArchived(String account);

  /// No description provided for @archiveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not archive. Please try again.'**
  String get archiveFailed;

  /// No description provided for @defaultAccountsRestored.
  ///
  /// In en, this message translates to:
  /// **'Default accounts restored without changing existing balances'**
  String get defaultAccountsRestored;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not restore. Please try again.'**
  String get restoreFailed;

  /// No description provided for @personalLiquidAssets.
  ///
  /// In en, this message translates to:
  /// **'Personal liquid assets'**
  String get personalLiquidAssets;

  /// No description provided for @outstandingLiabilities.
  ///
  /// In en, this message translates to:
  /// **'Outstanding liabilities'**
  String get outstandingLiabilities;

  /// No description provided for @entrustedFunds.
  ///
  /// In en, this message translates to:
  /// **'Entrusted / authorized funds'**
  String get entrustedFunds;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccount;

  /// No description provided for @restoreDefaults.
  ///
  /// In en, this message translates to:
  /// **'Restore defaults'**
  String get restoreDefaults;

  /// No description provided for @personalAccounts.
  ///
  /// In en, this message translates to:
  /// **'Personal accounts'**
  String get personalAccounts;

  /// No description provided for @personalAccountsDescription.
  ///
  /// In en, this message translates to:
  /// **'Cash, bank, and wallet balances you own'**
  String get personalAccountsDescription;

  /// No description provided for @entrustedFundsDescription.
  ///
  /// In en, this message translates to:
  /// **'Available to use but excluded from personal assets'**
  String get entrustedFundsDescription;

  /// No description provided for @liabilityAccounts.
  ///
  /// In en, this message translates to:
  /// **'Liability accounts'**
  String get liabilityAccounts;

  /// No description provided for @liabilityAccountsDescription.
  ///
  /// In en, this message translates to:
  /// **'Amounts currently owed'**
  String get liabilityAccountsDescription;

  /// No description provided for @accountCalibrationHint.
  ///
  /// In en, this message translates to:
  /// **'Tap an account to calibrate its current balance. Future expenses subtract from asset accounts or increase the balance owed on liability accounts.'**
  String get accountCalibrationHint;

  /// No description provided for @addAccountOrLiability.
  ///
  /// In en, this message translates to:
  /// **'Add account or liability'**
  String get addAccountOrLiability;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @liabilityNameExample.
  ///
  /// In en, this message translates to:
  /// **'For example: Loan from a friend'**
  String get liabilityNameExample;

  /// No description provided for @assetNameExample.
  ///
  /// In en, this message translates to:
  /// **'For example: Savings account'**
  String get assetNameExample;

  /// No description provided for @accountingType.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get accountingType;

  /// No description provided for @currentAmountOwed.
  ///
  /// In en, this message translates to:
  /// **'Current amount owed'**
  String get currentAmountOwed;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get currentBalance;

  /// No description provided for @zeroThenCalibrate.
  ///
  /// In en, this message translates to:
  /// **'You can enter 0 and calibrate it later'**
  String get zeroThenCalibrate;

  /// No description provided for @adding.
  ///
  /// In en, this message translates to:
  /// **'Adding…'**
  String get adding;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get enterName;

  /// No description provided for @nameAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'That name already exists'**
  String get nameAlreadyExists;

  /// No description provided for @addFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not add. Please try again.'**
  String get addFailed;

  /// No description provided for @accountKindCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountKindCash;

  /// No description provided for @accountKindBank.
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get accountKindBank;

  /// No description provided for @accountKindWallet.
  ///
  /// In en, this message translates to:
  /// **'Payment wallet'**
  String get accountKindWallet;

  /// No description provided for @accountKindEntrustedFunds.
  ///
  /// In en, this message translates to:
  /// **'Entrusted / authorized funds'**
  String get accountKindEntrustedFunds;

  /// No description provided for @accountKindLiability.
  ///
  /// In en, this message translates to:
  /// **'Liability account'**
  String get accountKindLiability;

  /// No description provided for @calibrateLiability.
  ///
  /// In en, this message translates to:
  /// **'Calibrate {account} liability'**
  String calibrateLiability(String account);

  /// No description provided for @calibrateBalance.
  ///
  /// In en, this message translates to:
  /// **'Calibrate {account} balance'**
  String calibrateBalance(String account);

  /// No description provided for @nonNegativeTwoDecimals.
  ///
  /// In en, this message translates to:
  /// **'Must not be negative; up to two decimal places'**
  String get nonNegativeTwoDecimals;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Please try again.'**
  String get saveFailed;

  /// No description provided for @liability.
  ///
  /// In en, this message translates to:
  /// **'Liability'**
  String get liability;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @accountActions.
  ///
  /// In en, this message translates to:
  /// **'Account actions'**
  String get accountActions;

  /// No description provided for @archiveAccount.
  ///
  /// In en, this message translates to:
  /// **'Archive account'**
  String get archiveAccount;

  /// No description provided for @moneyInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount with up to two decimal places'**
  String get moneyInvalidFormat;

  /// No description provided for @moneyNotNegative.
  ///
  /// In en, this message translates to:
  /// **'Amount must not be negative'**
  String get moneyNotNegative;

  /// No description provided for @moneyGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero'**
  String get moneyGreaterThanZero;

  /// No description provided for @restoreDefaultCategories.
  ///
  /// In en, this message translates to:
  /// **'Restore default categories'**
  String get restoreDefaultCategories;

  /// No description provided for @restoreDefaultCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore default categories?'**
  String get restoreDefaultCategoriesTitle;

  /// No description provided for @restoreDefaultCategoriesDescription.
  ///
  /// In en, this message translates to:
  /// **'Only missing default categories will be re-enabled. Custom categories will not be deleted or reset.'**
  String get restoreDefaultCategoriesDescription;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @defaultCategoriesRestored.
  ///
  /// In en, this message translates to:
  /// **'Default categories restored; custom categories were not changed'**
  String get defaultCategoriesRestored;

  /// No description provided for @categoryReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load categories'**
  String get categoryReadFailed;

  /// No description provided for @categoryStructureHint.
  ///
  /// In en, this message translates to:
  /// **'Primary categories are used for totals, while secondary categories are used by transactions. Historical transactions keep the names of archived categories.'**
  String get categoryStructureHint;

  /// No description provided for @addPrimaryCategory.
  ///
  /// In en, this message translates to:
  /// **'Add primary category'**
  String get addPrimaryCategory;

  /// No description provided for @secondaryCategoryCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No secondary categories} =1{1 secondary category} other{{count} secondary categories}}'**
  String secondaryCategoryCount(int count);

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @archiveCategory.
  ///
  /// In en, this message translates to:
  /// **'Archive category'**
  String get archiveCategory;

  /// No description provided for @addSecondaryCategory.
  ///
  /// In en, this message translates to:
  /// **'Add secondary category'**
  String get addSecondaryCategory;

  /// No description provided for @addToCategory.
  ///
  /// In en, this message translates to:
  /// **'Add to “{category}”'**
  String addToCategory(String category);

  /// No description provided for @renamePrimaryCategory.
  ///
  /// In en, this message translates to:
  /// **'Rename primary category'**
  String get renamePrimaryCategory;

  /// No description provided for @renameSecondaryCategory.
  ///
  /// In en, this message translates to:
  /// **'Rename secondary category'**
  String get renameSecondaryCategory;

  /// No description provided for @archiveCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive “{category}”?'**
  String archiveCategoryTitle(String category);

  /// No description provided for @archivePrimaryCategoryDescription.
  ///
  /// In en, this message translates to:
  /// **'This primary category and its secondary categories will no longer be available for new transactions. Historical transactions are not affected.'**
  String get archivePrimaryCategoryDescription;

  /// No description provided for @archiveSecondaryCategoryDescription.
  ///
  /// In en, this message translates to:
  /// **'This category will no longer be available for new transactions. Historical transactions are not affected.'**
  String get archiveSecondaryCategoryDescription;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @categoryNameNoSlash.
  ///
  /// In en, this message translates to:
  /// **'Names cannot contain /'**
  String get categoryNameNoSlash;

  /// No description provided for @categoryNameInvalidOrDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Invalid name or another category at this level already uses it'**
  String get categoryNameInvalidOrDuplicate;

  /// No description provided for @calibrateBalanceAction.
  ///
  /// In en, this message translates to:
  /// **'Calibrate balance'**
  String get calibrateBalanceAction;

  /// No description provided for @insufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'{account} has insufficient funds. Available: {amount}'**
  String insufficientBalance(String account, String amount);

  /// No description provided for @overpayment.
  ///
  /// In en, this message translates to:
  /// **'{account} has only {amount} outstanding and cannot be reduced further'**
  String overpayment(String account, String amount);

  /// No description provided for @fixedOtherCategory.
  ///
  /// In en, this message translates to:
  /// **'“Other” is the required fallback for this primary category'**
  String get fixedOtherCategory;

  /// No description provided for @otherCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Every primary category must keep an “Other” secondary category'**
  String get otherCategoryRequired;

  /// No description provided for @editTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get editTransaction;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @categoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load categories'**
  String get categoryLoadFailed;

  /// No description provided for @accountLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load accounts'**
  String get accountLoadFailed;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @saveTransaction.
  ///
  /// In en, this message translates to:
  /// **'Save transaction'**
  String get saveTransaction;

  /// No description provided for @expenseNoteHint.
  ///
  /// In en, this message translates to:
  /// **'What was this money spent on?'**
  String get expenseNoteHint;

  /// No description provided for @incomeNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Where did this money come from?'**
  String get incomeNoteHint;

  /// No description provided for @transferNoteHint.
  ///
  /// In en, this message translates to:
  /// **'For example: Alipay to WeChat Pay'**
  String get transferNoteHint;

  /// No description provided for @borrowingNoteHint.
  ///
  /// In en, this message translates to:
  /// **'For example: Loan from a friend'**
  String get borrowingNoteHint;

  /// No description provided for @repaymentNoteHint.
  ///
  /// In en, this message translates to:
  /// **'For example: Repay a friend'**
  String get repaymentNoteHint;

  /// No description provided for @primaryCategory.
  ///
  /// In en, this message translates to:
  /// **'Primary category'**
  String get primaryCategory;

  /// No description provided for @secondaryCategory.
  ///
  /// In en, this message translates to:
  /// **'Secondary category'**
  String get secondaryCategory;

  /// No description provided for @paymentAccount.
  ///
  /// In en, this message translates to:
  /// **'Payment account'**
  String get paymentAccount;

  /// No description provided for @incomeDestinationAccount.
  ///
  /// In en, this message translates to:
  /// **'Income destination account'**
  String get incomeDestinationAccount;

  /// No description provided for @archivedName.
  ///
  /// In en, this message translates to:
  /// **'{name} (archived)'**
  String archivedName(String name);

  /// No description provided for @quickAddLiability.
  ///
  /// In en, this message translates to:
  /// **'Quick-add liability account'**
  String get quickAddLiability;

  /// No description provided for @fundsDestinationAccount.
  ///
  /// In en, this message translates to:
  /// **'Funds destination account'**
  String get fundsDestinationAccount;

  /// No description provided for @repaymentSourceAccount.
  ///
  /// In en, this message translates to:
  /// **'Payment account'**
  String get repaymentSourceAccount;

  /// No description provided for @repaymentLiabilityAccount.
  ///
  /// In en, this message translates to:
  /// **'Liability to repay'**
  String get repaymentLiabilityAccount;

  /// No description provided for @transferFromAccount.
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get transferFromAccount;

  /// No description provided for @transferToAccount.
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get transferToAccount;

  /// No description provided for @addAvailableAccountFirst.
  ///
  /// In en, this message translates to:
  /// **'Add an available account first'**
  String get addAvailableAccountFirst;

  /// No description provided for @liabilityName.
  ///
  /// In en, this message translates to:
  /// **'{name} (liability)'**
  String liabilityName(String name);

  /// No description provided for @selectRequiredAccountAndCategory.
  ///
  /// In en, this message translates to:
  /// **'Select the required accounts and category'**
  String get selectRequiredAccountAndCategory;

  /// No description provided for @transactionChangesSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get transactionChangesSaved;

  /// No description provided for @transactionSavedLocally.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved locally'**
  String get transactionSavedLocally;

  /// No description provided for @saveLaterFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Please try again later.'**
  String get saveLaterFailed;

  /// No description provided for @confirmImportCount.
  ///
  /// In en, this message translates to:
  /// **'Import {count, plural, =1{1 transaction} other{{count} transactions}}?'**
  String confirmImportCount(int count);

  /// No description provided for @jsonImportInstructions.
  ///
  /// In en, this message translates to:
  /// **'Paste a single object, an array, or a schema_version 1 JSON batch. Amounts must be strings and categories use “Primary/Secondary”.'**
  String get jsonImportInstructions;

  /// No description provided for @jsonCode.
  ///
  /// In en, this message translates to:
  /// **'JSON code'**
  String get jsonCode;

  /// No description provided for @importTemplateCopied.
  ///
  /// In en, this message translates to:
  /// **'Import template copied'**
  String get importTemplateCopied;

  /// No description provided for @copyTemplate.
  ///
  /// In en, this message translates to:
  /// **'Copy template'**
  String get copyTemplate;

  /// No description provided for @parseAndPreview.
  ///
  /// In en, this message translates to:
  /// **'Parse & preview'**
  String get parseAndPreview;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @willCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create {kind} account: {name}'**
  String willCreateAccount(String kind, String name);

  /// No description provided for @removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get removeItem;

  /// No description provided for @backToCode.
  ///
  /// In en, this message translates to:
  /// **'Back to code'**
  String get backToCode;

  /// No description provided for @importing.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get importing;

  /// No description provided for @confirmImportButton.
  ///
  /// In en, this message translates to:
  /// **'Import {count}'**
  String confirmImportButton(int count);

  /// No description provided for @importedCount.
  ///
  /// In en, this message translates to:
  /// **'Imported {count, plural, =1{1 transaction} other{{count} transactions}}'**
  String importedCount(int count);

  /// No description provided for @batchNotImportedReason.
  ///
  /// In en, this message translates to:
  /// **'Nothing was imported: {reason}'**
  String batchNotImportedReason(String reason);

  /// No description provided for @batchNotImported.
  ///
  /// In en, this message translates to:
  /// **'Nothing was imported. Review the content and try again.'**
  String get batchNotImported;

  /// No description provided for @editTypedTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit {type} transaction'**
  String editTypedTransaction(String type);

  /// No description provided for @isoTimestamp.
  ///
  /// In en, this message translates to:
  /// **'ISO 8601 timestamp'**
  String get isoTimestamp;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @targetAccount.
  ///
  /// In en, this message translates to:
  /// **'Target account'**
  String get targetAccount;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @invalidTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Invalid timestamp'**
  String get invalidTimestamp;

  /// No description provided for @accountKindElectronicWallet.
  ///
  /// In en, this message translates to:
  /// **'Electronic wallet'**
  String get accountKindElectronicWallet;

  /// No description provided for @accountKindEntrustedShort.
  ///
  /// In en, this message translates to:
  /// **'Entrusted / authorized funds'**
  String get accountKindEntrustedShort;

  /// No description provided for @reportReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load reports'**
  String get reportReadFailed;

  /// No description provided for @periodDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get periodDay;

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get periodMonth;

  /// No description provided for @periodYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get periodYear;

  /// No description provided for @expenseCategories.
  ///
  /// In en, this message translates to:
  /// **'Expense categories'**
  String get expenseCategories;

  /// No description provided for @noExpenseCategoryData.
  ///
  /// In en, this message translates to:
  /// **'No expense category data for this period'**
  String get noExpenseCategoryData;

  /// No description provided for @incomeCategories.
  ///
  /// In en, this message translates to:
  /// **'Income categories'**
  String get incomeCategories;

  /// No description provided for @noIncomeCategoryData.
  ///
  /// In en, this message translates to:
  /// **'No income category data for this period'**
  String get noIncomeCategoryData;

  /// No description provided for @exportTransactions.
  ///
  /// In en, this message translates to:
  /// **'Export transactions'**
  String get exportTransactions;

  /// No description provided for @incomeExpenseBalance.
  ///
  /// In en, this message translates to:
  /// **'Income – expense'**
  String get incomeExpenseBalance;

  /// No description provided for @borrowingRepayment.
  ///
  /// In en, this message translates to:
  /// **'Borrowing / repayment'**
  String get borrowingRepayment;

  /// No description provided for @expenseTrend.
  ///
  /// In en, this message translates to:
  /// **'Expense trend'**
  String get expenseTrend;

  /// No description provided for @noExpensesThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'No expenses for this period'**
  String get noExpensesThisPeriod;

  /// No description provided for @liabilityTrend.
  ///
  /// In en, this message translates to:
  /// **'Liability trend'**
  String get liabilityTrend;

  /// No description provided for @closingAmount.
  ///
  /// In en, this message translates to:
  /// **'Closing {amount}'**
  String closingAmount(String amount);

  /// No description provided for @noLiabilityData.
  ///
  /// In en, this message translates to:
  /// **'No liability accounts or liability changes'**
  String get noLiabilityData;

  /// No description provided for @liabilityRangeSummary.
  ///
  /// In en, this message translates to:
  /// **'Opening {opening} · Current total liabilities {current}'**
  String liabilityRangeSummary(String opening, String current);

  /// No description provided for @timeRange.
  ///
  /// In en, this message translates to:
  /// **'Time range'**
  String get timeRange;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get thisYear;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get customRange;

  /// No description provided for @fileFormat.
  ///
  /// In en, this message translates to:
  /// **'File format'**
  String get fileFormat;

  /// No description provided for @jsonFormatDescription.
  ///
  /// In en, this message translates to:
  /// **'JSON (complete and re-importable)'**
  String get jsonFormatDescription;

  /// No description provided for @csvFormatDescription.
  ///
  /// In en, this message translates to:
  /// **'CSV (spreadsheet analysis)'**
  String get csvFormatDescription;

  /// No description provided for @markdownFormatDescription.
  ///
  /// In en, this message translates to:
  /// **'Markdown (readable)'**
  String get markdownFormatDescription;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get preparing;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @transactionExportSubject.
  ///
  /// In en, this message translates to:
  /// **'Summa transaction export'**
  String get transactionExportSubject;

  /// No description provided for @backupUnderYourControl.
  ///
  /// In en, this message translates to:
  /// **'Your complete backups, under your control'**
  String get backupUnderYourControl;

  /// No description provided for @backupLocationDescription.
  ///
  /// In en, this message translates to:
  /// **'Local snapshots are stored in Summa\'s app-specific documents directory. Recent Android file managers may not show it directly, so manage or export snapshots here.'**
  String get backupLocationDescription;

  /// No description provided for @automaticBackups.
  ///
  /// In en, this message translates to:
  /// **'Automatic backups'**
  String get automaticBackups;

  /// No description provided for @automaticBackupsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Saved before the first successful change after each launch; the latest five snapshots are retained.'**
  String get automaticBackupsSubtitle;

  /// No description provided for @noAutomaticBackupYet.
  ///
  /// In en, this message translates to:
  /// **'No successful changes have occurred during this launch'**
  String get noAutomaticBackupYet;

  /// No description provided for @manualBackups.
  ///
  /// In en, this message translates to:
  /// **'Manual backups'**
  String get manualBackups;

  /// No description provided for @manualBackupsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local snapshots remain inside the app; exported backups can be saved to a file manager, cloud drive, or another location.'**
  String get manualBackupsSubtitle;

  /// No description provided for @backupInsideApp.
  ///
  /// In en, this message translates to:
  /// **'Back up inside the app'**
  String get backupInsideApp;

  /// No description provided for @backupInsideAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a manual snapshot that is not limited by the five automatic slots'**
  String get backupInsideAppSubtitle;

  /// No description provided for @exportOrShareBackup.
  ///
  /// In en, this message translates to:
  /// **'Export or share backup'**
  String get exportOrShareBackup;

  /// No description provided for @exportOrShareBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a complete Summa JSON backup and hand it to the system'**
  String get exportOrShareBackupSubtitle;

  /// No description provided for @restoreExternalBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore an external backup file'**
  String get restoreExternalBackup;

  /// No description provided for @restoreExternalBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a JSON file, then replace or merge the ledger'**
  String get restoreExternalBackupSubtitle;

  /// No description provided for @noManualBackups.
  ///
  /// In en, this message translates to:
  /// **'No manual local backups yet'**
  String get noManualBackups;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @resetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Resetting the ledger preserves local backups; factory reset deletes them as well.'**
  String get resetSubtitle;

  /// No description provided for @resetTransactionsAccounts.
  ///
  /// In en, this message translates to:
  /// **'Reset transactions & accounts'**
  String get resetTransactionsAccounts;

  /// No description provided for @resetTransactionsAccountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear transactions, restore zero-balance default accounts, and preserve categories and backups'**
  String get resetTransactionsAccountsSubtitle;

  /// No description provided for @factoryReset.
  ///
  /// In en, this message translates to:
  /// **'Factory reset'**
  String get factoryReset;

  /// No description provided for @factoryResetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear transactions, accounts, categories, and every local backup'**
  String get factoryResetSubtitle;

  /// No description provided for @cannotReadBackupDirectory.
  ///
  /// In en, this message translates to:
  /// **'Could not read the local backup directory'**
  String get cannotReadBackupDirectory;

  /// No description provided for @manualBackupName.
  ///
  /// In en, this message translates to:
  /// **'Manual backup name'**
  String get manualBackupName;

  /// No description provided for @myBackup.
  ///
  /// In en, this message translates to:
  /// **'My backup'**
  String get myBackup;

  /// No description provided for @manualBackupSaved.
  ///
  /// In en, this message translates to:
  /// **'Manual backup saved inside the app'**
  String get manualBackupSaved;

  /// No description provided for @createLocalBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the local backup'**
  String get createLocalBackupFailed;

  /// No description provided for @completeBackupSubject.
  ///
  /// In en, this message translates to:
  /// **'Summa complete backup'**
  String get completeBackupSubject;

  /// No description provided for @backupExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not export the backup. Please try again.'**
  String get backupExportFailed;

  /// No description provided for @cannotReadSelectedBackup.
  ///
  /// In en, this message translates to:
  /// **'Could not read the selected backup file'**
  String get cannotReadSelectedBackup;

  /// No description provided for @renameBackup.
  ///
  /// In en, this message translates to:
  /// **'Rename backup'**
  String get renameBackup;

  /// No description provided for @renameBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not rename. Check whether a backup already uses that name.'**
  String get renameBackupFailed;

  /// No description provided for @deleteBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete backup snapshot?'**
  String get deleteBackupTitle;

  /// No description provided for @deleteBackupMessage.
  ///
  /// In en, this message translates to:
  /// **'“{name}” will be permanently deleted. This cannot be undone.'**
  String deleteBackupMessage(String name);

  /// No description provided for @deleteBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the backup'**
  String get deleteBackupFailed;

  /// No description provided for @backupNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'The backup snapshot no longer exists or cannot be read'**
  String get backupNoLongerAvailable;

  /// No description provided for @restoredSelectedBackup.
  ///
  /// In en, this message translates to:
  /// **'Restored the selected backup'**
  String get restoredSelectedBackup;

  /// No description provided for @backupMerged.
  ///
  /// In en, this message translates to:
  /// **'Backup merged'**
  String get backupMerged;

  /// No description provided for @restoreDatabaseSafeFailure.
  ///
  /// In en, this message translates to:
  /// **'Restore failed; the database was not partially changed'**
  String get restoreDatabaseSafeFailure;

  /// No description provided for @confirmRestoreContents.
  ///
  /// In en, this message translates to:
  /// **'Confirm restore contents'**
  String get confirmRestoreContents;

  /// No description provided for @merge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get merge;

  /// No description provided for @replaceAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Replace & restore'**
  String get replaceAndRestore;

  /// No description provided for @restoreThisSnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore this snapshot?'**
  String get restoreThisSnapshotTitle;

  /// No description provided for @mergeThisSnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge this snapshot?'**
  String get mergeThisSnapshotTitle;

  /// No description provided for @confirmRestore.
  ///
  /// In en, this message translates to:
  /// **'Confirm restore'**
  String get confirmRestore;

  /// No description provided for @confirmMerge.
  ///
  /// In en, this message translates to:
  /// **'Confirm merge'**
  String get confirmMerge;

  /// No description provided for @resetTransactionsAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset transactions & accounts?'**
  String get resetTransactionsAccountsTitle;

  /// No description provided for @resetTransactionsAccountsMessage.
  ///
  /// In en, this message translates to:
  /// **'All transactions will be permanently cleared, custom accounts deleted, and default account balances set to zero. Categories and all backups will be preserved.'**
  String get resetTransactionsAccountsMessage;

  /// No description provided for @confirmReset.
  ///
  /// In en, this message translates to:
  /// **'Confirm reset'**
  String get confirmReset;

  /// No description provided for @transactionsAccountsReset.
  ///
  /// In en, this message translates to:
  /// **'Transactions and accounts reset; all backups were preserved'**
  String get transactionsAccountsReset;

  /// No description provided for @resetSafeFailure.
  ///
  /// In en, this message translates to:
  /// **'Reset failed; the data was not partially changed'**
  String get resetSafeFailure;

  /// No description provided for @factoryResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Factory reset?'**
  String get factoryResetTitle;

  /// No description provided for @factoryResetMessage.
  ///
  /// In en, this message translates to:
  /// **'Transactions, accounts, categories, and every in-app backup will be permanently cleared. Files exported outside the app are not affected.'**
  String get factoryResetMessage;

  /// No description provided for @clearEverything.
  ///
  /// In en, this message translates to:
  /// **'Clear everything'**
  String get clearEverything;

  /// No description provided for @factoryResetComplete.
  ///
  /// In en, this message translates to:
  /// **'Summa was reset to factory defaults'**
  String get factoryResetComplete;

  /// No description provided for @factoryResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Factory reset failed'**
  String get factoryResetFailed;

  /// No description provided for @tapToRestore.
  ///
  /// In en, this message translates to:
  /// **'Tap to restore'**
  String get tapToRestore;

  /// No description provided for @mergeIntoLedger.
  ///
  /// In en, this message translates to:
  /// **'Merge into current ledger'**
  String get mergeIntoLedger;

  /// No description provided for @backupTime.
  ///
  /// In en, this message translates to:
  /// **'Backup time: {time}'**
  String backupTime(String time);

  /// No description provided for @backupAccountCount.
  ///
  /// In en, this message translates to:
  /// **'Accounts: {count}'**
  String backupAccountCount(int count);

  /// No description provided for @backupCategoryCount.
  ///
  /// In en, this message translates to:
  /// **'Categories: {count}'**
  String backupCategoryCount(int count);

  /// No description provided for @backupTransactionCount.
  ///
  /// In en, this message translates to:
  /// **'Transactions: {count} ({deleted} deleted)'**
  String backupTransactionCount(int count, int deleted);

  /// No description provided for @restoreSafetyHint.
  ///
  /// In en, this message translates to:
  /// **'Before applying the operation, Summa protects the current state according to this launch\'s automatic-backup rule.'**
  String get restoreSafetyHint;

  /// No description provided for @automaticBackupName.
  ///
  /// In en, this message translates to:
  /// **'Automatic backup'**
  String get automaticBackupName;

  /// No description provided for @backupInvalidJson.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup JSON: {details}'**
  String backupInvalidJson(String details);

  /// No description provided for @backupUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This is not a supported Summa complete backup'**
  String get backupUnsupported;

  /// No description provided for @backupInvalidTime.
  ///
  /// In en, this message translates to:
  /// **'The backup timestamp is invalid'**
  String get backupInvalidTime;

  /// No description provided for @backupMissingList.
  ///
  /// In en, this message translates to:
  /// **'The backup is missing the {field} list'**
  String backupMissingList(String field);

  /// No description provided for @backupInvalidItem.
  ///
  /// In en, this message translates to:
  /// **'{field} contains an invalid item'**
  String backupInvalidItem(String field);

  /// No description provided for @backupFieldMustString.
  ///
  /// In en, this message translates to:
  /// **'Field {field} must be a string'**
  String backupFieldMustString(String field);

  /// No description provided for @backupFieldMustNullableString.
  ///
  /// In en, this message translates to:
  /// **'Field {field} must be a string or null'**
  String backupFieldMustNullableString(String field);

  /// No description provided for @backupFieldMustInteger.
  ///
  /// In en, this message translates to:
  /// **'Field {field} must be an integer'**
  String backupFieldMustInteger(String field);

  /// No description provided for @backupFieldMustBoolean.
  ///
  /// In en, this message translates to:
  /// **'Field {field} must be a boolean'**
  String backupFieldMustBoolean(String field);

  /// No description provided for @backupFieldInvalidTime.
  ///
  /// In en, this message translates to:
  /// **'Field {field} is not a valid timestamp'**
  String backupFieldInvalidTime(String field);

  /// No description provided for @backupFieldUnsupportedValue.
  ///
  /// In en, this message translates to:
  /// **'Field {field} has an unsupported value: {value}'**
  String backupFieldUnsupportedValue(String field, String value);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
