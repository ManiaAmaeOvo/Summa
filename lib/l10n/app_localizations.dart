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

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSize;

  /// No description provided for @fontSizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust text size throughout Summa'**
  String get fontSizeSubtitle;

  /// No description provided for @fontSizeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get fontSizeSystem;

  /// No description provided for @fontSizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get fontSizeSmall;

  /// No description provided for @fontSizeStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get fontSizeStandard;

  /// No description provided for @fontSizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get fontSizeLarge;

  /// No description provided for @fontSizeExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get fontSizeExtraLarge;

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
  /// **'Use the code icon in the top-right of Transactions to paste one or many JSON transactions. This is useful after an OCR tool or language model structures a statement screenshot.'**
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
  /// **'Clear transactions and account-linked plans, then restore zero-balance default accounts'**
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
  /// **'All transactions, recurring plans, debt and receivable contracts, savings goals, and account-linked budgets and allowances will be cleared. Custom accounts will be deleted and default balances set to zero. Categories, other budgets, and backups will be preserved.'**
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

  /// No description provided for @pendingPosting.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingPosting;

  /// No description provided for @saveAsPending.
  ///
  /// In en, this message translates to:
  /// **'Save as pending'**
  String get saveAsPending;

  /// No description provided for @pendingPostingHint.
  ///
  /// In en, this message translates to:
  /// **'Pending transactions stay outside balances and reports until posted.'**
  String get pendingPostingHint;

  /// No description provided for @postTransactionAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm posting'**
  String get postTransactionAction;

  /// No description provided for @transactionPosted.
  ///
  /// In en, this message translates to:
  /// **'Transaction posted'**
  String get transactionPosted;

  /// No description provided for @addPaymentAccount.
  ///
  /// In en, this message translates to:
  /// **'Add payment account'**
  String get addPaymentAccount;

  /// No description provided for @extraPaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount from this account'**
  String get extraPaymentAmount;

  /// No description provided for @removePaymentAccount.
  ///
  /// In en, this message translates to:
  /// **'Remove payment account'**
  String get removePaymentAccount;

  /// No description provided for @mainPaymentRemainder.
  ///
  /// In en, this message translates to:
  /// **'The first account pays the remaining amount.'**
  String get mainPaymentRemainder;

  /// No description provided for @invalidPaymentSplit.
  ///
  /// In en, this message translates to:
  /// **'Use distinct accounts with positive amounts that add up to the transaction total.'**
  String get invalidPaymentSplit;

  /// No description provided for @recordRefund.
  ///
  /// In en, this message translates to:
  /// **'Record refund'**
  String get recordRefund;

  /// No description provided for @editRefund.
  ///
  /// In en, this message translates to:
  /// **'Edit refund'**
  String get editRefund;

  /// No description provided for @refund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refund;

  /// No description provided for @refundAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available to refund: {amount}'**
  String refundAvailable(String amount);

  /// No description provided for @refundRecorded.
  ///
  /// In en, this message translates to:
  /// **'Refund saved'**
  String get refundRecorded;

  /// No description provided for @refundLimitExceeded.
  ///
  /// In en, this message translates to:
  /// **'The refund cannot exceed the remaining {amount} for this account.'**
  String refundLimitExceeded(String amount);

  /// No description provided for @linkedRefunds.
  ///
  /// In en, this message translates to:
  /// **'Remove the linked refunds before editing or deleting the original purchase.'**
  String get linkedRefunds;

  /// No description provided for @archivedPostingAccount.
  ///
  /// In en, this message translates to:
  /// **'An account is archived. Restore it or choose another account before posting.'**
  String get archivedPostingAccount;

  /// No description provided for @backupLedgerConflict.
  ///
  /// In en, this message translates to:
  /// **'This backup conflicts with the current ledger or contains invalid postings or refunds.'**
  String get backupLedgerConflict;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @summaryCurrency.
  ///
  /// In en, this message translates to:
  /// **'Summary currency'**
  String get summaryCurrency;

  /// No description provided for @invalidCurrencyAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount valid for {currency}.'**
  String invalidCurrencyAmount(String currency);

  /// No description provided for @transferSettlementAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount received'**
  String get transferSettlementAmount;

  /// No description provided for @quotedExchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Quoted rate (optional)'**
  String get quotedExchangeRate;

  /// No description provided for @exchangeRateDirection.
  ///
  /// In en, this message translates to:
  /// **'{target} per 1 {source}'**
  String exchangeRateDirection(String target, String source);

  /// No description provided for @effectiveExchangeRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Effective rate: 1 {source} = {rate} {target}'**
  String effectiveExchangeRateLabel(String source, String rate, String target);

  /// No description provided for @quotedExchangeRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Quoted rate: 1 {source} = {rate} {target}'**
  String quotedExchangeRateLabel(String source, String rate, String target);

  /// No description provided for @invalidQuotedExchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive decimal rate with up to 18 decimal places.'**
  String get invalidQuotedExchangeRate;

  /// No description provided for @invalidTransferSettlement.
  ///
  /// In en, this message translates to:
  /// **'A transfer between different currencies requires the actual amount received. Other transaction types require matching currencies.'**
  String get invalidTransferSettlement;

  /// No description provided for @currencyMismatch.
  ///
  /// In en, this message translates to:
  /// **'Choose accounts in the transaction’s currency.'**
  String get currencyMismatch;

  /// No description provided for @legacyTransferConflict.
  ///
  /// In en, this message translates to:
  /// **'The old backup would overwrite an existing cross-currency transfer.'**
  String get legacyTransferConflict;

  /// No description provided for @estimatedNetWorth.
  ///
  /// In en, this message translates to:
  /// **'Estimated net worth'**
  String get estimatedNetWorth;

  /// No description provided for @valuationSettings.
  ///
  /// In en, this message translates to:
  /// **'Valuation settings'**
  String get valuationSettings;

  /// No description provided for @valuationBaseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Base currency for valuation'**
  String get valuationBaseCurrency;

  /// No description provided for @valuationBaseDescription.
  ///
  /// In en, this message translates to:
  /// **'Valued in {currency}'**
  String valuationBaseDescription(String currency);

  /// No description provided for @missingValuationRates.
  ///
  /// In en, this message translates to:
  /// **'Add rates to value: {currencies}'**
  String missingValuationRates(String currencies);

  /// No description provided for @unsupportedValuationCurrencies.
  ///
  /// In en, this message translates to:
  /// **'Currency precision unavailable: {currencies}'**
  String unsupportedValuationCurrencies(String currencies);

  /// No description provided for @valuationReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load valuation settings.'**
  String get valuationReadFailed;

  /// No description provided for @valuationSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'These rates value today’s account balances. Each transfer shows its historical settlement rate in the transaction details.'**
  String get valuationSettingsHint;

  /// No description provided for @valuationRatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual valuation rates'**
  String get valuationRatesTitle;

  /// No description provided for @noValuationCurrencies.
  ///
  /// In en, this message translates to:
  /// **'The current accounts use the selected base currency.'**
  String get noValuationCurrencies;

  /// No description provided for @valuationRateMissing.
  ///
  /// In en, this message translates to:
  /// **'Rate required'**
  String get valuationRateMissing;

  /// No description provided for @valuationRateAsOf.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String valuationRateAsOf(String date);

  /// No description provided for @valuationRatePair.
  ///
  /// In en, this message translates to:
  /// **'{source} → {base}'**
  String valuationRatePair(String source, String base);

  /// No description provided for @editValuationRate.
  ///
  /// In en, this message translates to:
  /// **'Edit valuation rate'**
  String get editValuationRate;

  /// No description provided for @valuationRateField.
  ///
  /// In en, this message translates to:
  /// **'Valuation rate'**
  String get valuationRateField;

  /// No description provided for @invalidValuationRate.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive decimal rate with up to 18 decimal places.'**
  String get invalidValuationRate;

  /// No description provided for @removeValuationRate.
  ///
  /// In en, this message translates to:
  /// **'Remove rate'**
  String get removeValuationRate;

  /// No description provided for @invalidBackupValuation.
  ///
  /// In en, this message translates to:
  /// **'The backup contains invalid or duplicate valuation settings.'**
  String get invalidBackupValuation;

  /// No description provided for @familyDirectFunding.
  ///
  /// In en, this message translates to:
  /// **'Paid directly by family'**
  String get familyDirectFunding;

  /// No description provided for @familyDirectExplanation.
  ///
  /// In en, this message translates to:
  /// **'Records the purchase against family funding.'**
  String get familyDirectExplanation;

  /// No description provided for @lending.
  ///
  /// In en, this message translates to:
  /// **'Lend'**
  String get lending;

  /// No description provided for @advance.
  ///
  /// In en, this message translates to:
  /// **'Pay for someone'**
  String get advance;

  /// No description provided for @collection.
  ///
  /// In en, this message translates to:
  /// **'Collect principal'**
  String get collection;

  /// No description provided for @reimbursement.
  ///
  /// In en, this message translates to:
  /// **'Receive reimbursement'**
  String get reimbursement;

  /// No description provided for @receivableAccount.
  ///
  /// In en, this message translates to:
  /// **'Receivable account'**
  String get receivableAccount;

  /// No description provided for @accountKindReceivable.
  ///
  /// In en, this message translates to:
  /// **'Receivable'**
  String get accountKindReceivable;

  /// No description provided for @accountKindThirdPartyPayable.
  ///
  /// In en, this message translates to:
  /// **'Third-party payment due'**
  String get accountKindThirdPartyPayable;

  /// No description provided for @receivableAccounts.
  ///
  /// In en, this message translates to:
  /// **'Receivables'**
  String get receivableAccounts;

  /// No description provided for @receivableAccountsDescription.
  ///
  /// In en, this message translates to:
  /// **'Outstanding principal from loans and payments made for others.'**
  String get receivableAccountsDescription;

  /// No description provided for @quickAddReceivable.
  ///
  /// In en, this message translates to:
  /// **'Add a receivable account'**
  String get quickAddReceivable;

  /// No description provided for @receivableBalanceExceeded.
  ///
  /// In en, this message translates to:
  /// **'This change would make the outstanding receivable negative on its transaction date.'**
  String get receivableBalanceExceeded;

  /// No description provided for @grossSpending.
  ///
  /// In en, this message translates to:
  /// **'Total spending'**
  String get grossSpending;

  /// No description provided for @personalSpending.
  ///
  /// In en, this message translates to:
  /// **'Personally borne'**
  String get personalSpending;

  /// No description provided for @entrustedSpending.
  ///
  /// In en, this message translates to:
  /// **'Paid from entrusted funds'**
  String get entrustedSpending;

  /// No description provided for @thirdPartyPayableSpending.
  ///
  /// In en, this message translates to:
  /// **'Of personally borne, paid by others'**
  String get thirdPartyPayableSpending;

  /// No description provided for @unclassifiedSpending.
  ///
  /// In en, this message translates to:
  /// **'Funding to review'**
  String get unclassifiedSpending;

  /// No description provided for @familySupportReceived.
  ///
  /// In en, this message translates to:
  /// **'Family money received'**
  String get familySupportReceived;

  /// No description provided for @fundingAndCashFlow.
  ///
  /// In en, this message translates to:
  /// **'Funding and personal cash flow'**
  String get fundingAndCashFlow;

  /// No description provided for @personalCashInflow.
  ///
  /// In en, this message translates to:
  /// **'Personal cash inflow'**
  String get personalCashInflow;

  /// No description provided for @personalCashOutflow.
  ///
  /// In en, this message translates to:
  /// **'Personal cash outflow'**
  String get personalCashOutflow;

  /// No description provided for @personalCashFlowNet.
  ///
  /// In en, this message translates to:
  /// **'Net personal cash flow'**
  String get personalCashFlowNet;

  /// No description provided for @advancedFundingBackupError.
  ///
  /// In en, this message translates to:
  /// **'The backup conflicts with funding or receivable records.'**
  String get advancedFundingBackupError;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction details'**
  String get transactionDetails;

  /// No description provided for @foreignPurchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase priced in another currency'**
  String get foreignPurchase;

  /// No description provided for @originalPrice.
  ///
  /// In en, this message translates to:
  /// **'Original purchase amount'**
  String get originalPrice;

  /// No description provided for @originalCurrency.
  ///
  /// In en, this message translates to:
  /// **'Original currency'**
  String get originalCurrency;

  /// No description provided for @settledPurchaseAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount charged to payment account'**
  String get settledPurchaseAmount;

  /// No description provided for @splitCategories.
  ///
  /// In en, this message translates to:
  /// **'Add category split'**
  String get splitCategories;

  /// No description provided for @additionalCategory.
  ///
  /// In en, this message translates to:
  /// **'Additional category'**
  String get additionalCategory;

  /// No description provided for @categoryShare.
  ///
  /// In en, this message translates to:
  /// **'Category amount'**
  String get categoryShare;

  /// No description provided for @advanceForOthers.
  ///
  /// In en, this message translates to:
  /// **'Part of this bill is owed by someone else'**
  String get advanceForOthers;

  /// No description provided for @advanceShare.
  ///
  /// In en, this message translates to:
  /// **'Amount advanced for someone else'**
  String get advanceShare;

  /// No description provided for @feeAmount.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get feeAmount;

  /// No description provided for @interestAmount.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get interestAmount;

  /// No description provided for @externalDebtPayment.
  ///
  /// In en, this message translates to:
  /// **'Someone else paid this debt directly'**
  String get externalDebtPayment;

  /// No description provided for @externalDebtPaymentHint.
  ///
  /// In en, this message translates to:
  /// **'Use for principal you do not owe back to the payer.'**
  String get externalDebtPaymentHint;

  /// No description provided for @balanceAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Balance adjustment'**
  String get balanceAdjustment;

  /// No description provided for @balanceAdjustmentHint.
  ///
  /// In en, this message translates to:
  /// **'The difference will be saved as a balance adjustment.'**
  String get balanceAdjustmentHint;

  /// No description provided for @reverseTransaction.
  ///
  /// In en, this message translates to:
  /// **'Reverse posting'**
  String get reverseTransaction;

  /// No description provided for @confirmReversal.
  ///
  /// In en, this message translates to:
  /// **'Save an opposite entry dated today and keep both entries in history?'**
  String get confirmReversal;

  /// No description provided for @postedReversal.
  ///
  /// In en, this message translates to:
  /// **'Reversal saved'**
  String get postedReversal;

  /// No description provided for @reversedPosting.
  ///
  /// In en, this message translates to:
  /// **'Reversed'**
  String get reversedPosting;

  /// No description provided for @reversalPosting.
  ///
  /// In en, this message translates to:
  /// **'Reversal'**
  String get reversalPosting;

  /// No description provided for @linkedReversal.
  ///
  /// In en, this message translates to:
  /// **'This entry belongs to a reversal and its original. Both are kept in history.'**
  String get linkedReversal;

  /// No description provided for @invalidTransactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Check the accounts, amounts, and categories for this entry.'**
  String get invalidTransactionDetails;

  /// No description provided for @fundingReviewFilter.
  ///
  /// In en, this message translates to:
  /// **'Only entries needing review'**
  String get fundingReviewFilter;

  /// No description provided for @fundingReviewBadge.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get fundingReviewBadge;

  /// No description provided for @fundingReviewHint.
  ///
  /// In en, this message translates to:
  /// **'This historical entry has ambiguous accounting details. Review the original receipt and save a correction when the details are known.'**
  String get fundingReviewHint;

  /// No description provided for @financialChargesCategory.
  ///
  /// In en, this message translates to:
  /// **'Financial charges'**
  String get financialChargesCategory;

  /// No description provided for @refundAdvanceShare.
  ///
  /// In en, this message translates to:
  /// **'Reduce receivable by'**
  String get refundAdvanceShare;

  /// No description provided for @refundAdvanceHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. If blank, the refund reduces spending first, then outstanding receivables.'**
  String get refundAdvanceHint;

  /// No description provided for @accountKindSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings account'**
  String get accountKindSavings;

  /// No description provided for @accountKindPrepaid.
  ///
  /// In en, this message translates to:
  /// **'Prepaid balance'**
  String get accountKindPrepaid;

  /// No description provided for @prepaidAccounts.
  ///
  /// In en, this message translates to:
  /// **'Prepaid accounts'**
  String get prepaidAccounts;

  /// No description provided for @prepaidAccountsDescription.
  ///
  /// In en, this message translates to:
  /// **'Stored value available for future purchases. Excluded from liquid assets.'**
  String get prepaidAccountsDescription;

  /// No description provided for @reconciliation.
  ///
  /// In en, this message translates to:
  /// **'Reconcile account'**
  String get reconciliation;

  /// No description provided for @recordCheckpoint.
  ///
  /// In en, this message translates to:
  /// **'Record checkpoint'**
  String get recordCheckpoint;

  /// No description provided for @checkpointDetails.
  ///
  /// In en, this message translates to:
  /// **'Checkpoint details'**
  String get checkpointDetails;

  /// No description provided for @checkpointTime.
  ///
  /// In en, this message translates to:
  /// **'Observed at'**
  String get checkpointTime;

  /// No description provided for @observedBalance.
  ///
  /// In en, this message translates to:
  /// **'Observed balance'**
  String get observedBalance;

  /// No description provided for @noCheckpoints.
  ///
  /// In en, this message translates to:
  /// **'There are no balance checkpoints for this account.'**
  String get noCheckpoints;

  /// No description provided for @noSuccessfulReconciliation.
  ///
  /// In en, this message translates to:
  /// **'No balanced checkpoint yet'**
  String get noSuccessfulReconciliation;

  /// No description provided for @lastSuccessfulReconciliation.
  ///
  /// In en, this message translates to:
  /// **'Last balanced checkpoint {date}'**
  String lastSuccessfulReconciliation(String date);

  /// No description provided for @checkpointBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get checkpointBalanced;

  /// No description provided for @checkpointUnbalanced.
  ///
  /// In en, this message translates to:
  /// **'Difference to review'**
  String get checkpointUnbalanced;

  /// No description provided for @checkpointDifference.
  ///
  /// In en, this message translates to:
  /// **'Difference (observed minus book)'**
  String get checkpointDifference;

  /// No description provided for @bookBalanceAtCheckpoint.
  ///
  /// In en, this message translates to:
  /// **'Book balance at this time'**
  String get bookBalanceAtCheckpoint;

  /// No description provided for @recordedBookBalance.
  ///
  /// In en, this message translates to:
  /// **'Book balance when recorded'**
  String get recordedBookBalance;

  /// No description provided for @voidedCheckpoint.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get voidedCheckpoint;

  /// No description provided for @voidCheckpoint.
  ///
  /// In en, this message translates to:
  /// **'Void checkpoint'**
  String get voidCheckpoint;

  /// No description provided for @confirmVoidCheckpoint.
  ///
  /// In en, this message translates to:
  /// **'Void this observation? It will remain in the account history.'**
  String get confirmVoidCheckpoint;

  /// No description provided for @confirmVoidAdjustedCheckpoint.
  ///
  /// In en, this message translates to:
  /// **'Void this observation and undo its linked balance adjustment? Both records will be kept in the audit history.'**
  String get confirmVoidAdjustedCheckpoint;

  /// No description provided for @applyCheckpointAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Post difference as adjustment'**
  String get applyCheckpointAdjustment;

  /// No description provided for @confirmCheckpointAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Post an adjustment at the observed time using the displayed difference?'**
  String get confirmCheckpointAdjustment;

  /// No description provided for @linkedAdjustmentRecorded.
  ///
  /// In en, this message translates to:
  /// **'This checkpoint has a linked balance adjustment.'**
  String get linkedAdjustmentRecorded;

  /// No description provided for @linkedCheckpoint.
  ///
  /// In en, this message translates to:
  /// **'Void the linked checkpoint to undo this adjustment.'**
  String get linkedCheckpoint;

  /// No description provided for @checkpointUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The checkpoint or account is unavailable. Check that the date is in the past and the account is active.'**
  String get checkpointUnavailable;

  /// No description provided for @checkpointChanged.
  ///
  /// In en, this message translates to:
  /// **'The book balance changed. Review the new difference and confirm again.'**
  String get checkpointChanged;

  /// No description provided for @reconciliationCandidates.
  ///
  /// In en, this message translates to:
  /// **'Transactions to review'**
  String get reconciliationCandidates;

  /// No description provided for @checkpointRange.
  ///
  /// In en, this message translates to:
  /// **'After {start} through {end}'**
  String checkpointRange(String start, String end);

  /// No description provided for @checkpointRangeThrough.
  ///
  /// In en, this message translates to:
  /// **'Through {end}'**
  String checkpointRangeThrough(String end);

  /// No description provided for @checkpointMatchingAmount.
  ///
  /// In en, this message translates to:
  /// **'Could account for the difference'**
  String get checkpointMatchingAmount;

  /// No description provided for @similarCheckpointMovement.
  ///
  /// In en, this message translates to:
  /// **'Similar transaction in this period'**
  String get similarCheckpointMovement;

  /// No description provided for @noReconciliationCandidates.
  ///
  /// In en, this message translates to:
  /// **'No transactions in this interval. Check for missing entries.'**
  String get noReconciliationCandidates;

  /// No description provided for @checkpointCandidateLimit.
  ///
  /// In en, this message translates to:
  /// **'Showing the first 12 candidates.'**
  String get checkpointCandidateLimit;

  /// No description provided for @backupCheckpointCount.
  ///
  /// In en, this message translates to:
  /// **'Balance checkpoints {count}'**
  String backupCheckpointCount(int count);

  /// No description provided for @checkpointBackupConflict.
  ///
  /// In en, this message translates to:
  /// **'The backup has invalid or conflicting balance checkpoints.'**
  String get checkpointBackupConflict;

  /// No description provided for @csvImport.
  ///
  /// In en, this message translates to:
  /// **'CSV import'**
  String get csvImport;

  /// No description provided for @csvHistory.
  ///
  /// In en, this message translates to:
  /// **'Import batches'**
  String get csvHistory;

  /// No description provided for @csvInstructions.
  ///
  /// In en, this message translates to:
  /// **'Choose a generic CSV or a WeChat Pay or Alipay CSV/XLSX statement. Review the rows before posting.'**
  String get csvInstructions;

  /// No description provided for @csvChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose statement file'**
  String get csvChooseFile;

  /// No description provided for @csvPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste CSV'**
  String get csvPaste;

  /// No description provided for @csvPastedFile.
  ///
  /// In en, this message translates to:
  /// **'Pasted CSV'**
  String get csvPastedFile;

  /// No description provided for @csvReviewSummary.
  ///
  /// In en, this message translates to:
  /// **'{total} rows · {selected} selected'**
  String csvReviewSummary(int total, int selected);

  /// No description provided for @csvCommit.
  ///
  /// In en, this message translates to:
  /// **'Confirm {count} selected'**
  String csvCommit(int count);

  /// No description provided for @csvChangeFile.
  ///
  /// In en, this message translates to:
  /// **'Change input'**
  String get csvChangeFile;

  /// No description provided for @csvRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh review'**
  String get csvRefresh;

  /// No description provided for @csvLine.
  ///
  /// In en, this message translates to:
  /// **'Line {line}'**
  String csvLine(int line);

  /// No description provided for @csvReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to import'**
  String get csvReady;

  /// No description provided for @csvUnresolved.
  ///
  /// In en, this message translates to:
  /// **'Choose account or category'**
  String get csvUnresolved;

  /// No description provided for @csvSimilar.
  ///
  /// In en, this message translates to:
  /// **'Possible match'**
  String get csvSimilar;

  /// No description provided for @csvDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Already imported or repeated in file'**
  String get csvDuplicate;

  /// No description provided for @csvSourceConflict.
  ///
  /// In en, this message translates to:
  /// **'Same source and ID with conflicting values'**
  String get csvSourceConflict;

  /// No description provided for @csvInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid row'**
  String get csvInvalid;

  /// No description provided for @csvLinkedRow.
  ///
  /// In en, this message translates to:
  /// **'Matched to existing transaction'**
  String get csvLinkedRow;

  /// No description provided for @csvCreatedRow.
  ///
  /// In en, this message translates to:
  /// **'Created transaction'**
  String get csvCreatedRow;

  /// No description provided for @csvSeparateRow.
  ///
  /// In en, this message translates to:
  /// **'Approved as a distinct transaction'**
  String get csvSeparateRow;

  /// No description provided for @csvSourceAccount.
  ///
  /// In en, this message translates to:
  /// **'Posting account'**
  String get csvSourceAccount;

  /// No description provided for @csvTargetAccount.
  ///
  /// In en, this message translates to:
  /// **'Destination account'**
  String get csvTargetAccount;

  /// No description provided for @csvNoEligibleAccounts.
  ///
  /// In en, this message translates to:
  /// **'Create a compatible account in Accounts, then return to review.'**
  String get csvNoEligibleAccounts;

  /// No description provided for @csvReviewMapping.
  ///
  /// In en, this message translates to:
  /// **'Check assignment'**
  String get csvReviewMapping;

  /// No description provided for @csvSimilarHint.
  ///
  /// In en, this message translates to:
  /// **'Tap an existing transaction to link it. If this row represents a separate payment, approve it as a new entry.'**
  String get csvSimilarHint;

  /// No description provided for @csvEarlierSource.
  ///
  /// In en, this message translates to:
  /// **'Also seen in an earlier batch'**
  String get csvEarlierSource;

  /// No description provided for @csvCategoryForNew.
  ///
  /// In en, this message translates to:
  /// **'Choose a category before posting a new entry.'**
  String get csvCategoryForNew;

  /// No description provided for @csvSkipRow.
  ///
  /// In en, this message translates to:
  /// **'Skip row'**
  String get csvSkipRow;

  /// No description provided for @csvChangeMapping.
  ///
  /// In en, this message translates to:
  /// **'Change assignment'**
  String get csvChangeMapping;

  /// No description provided for @csvAddSeparately.
  ///
  /// In en, this message translates to:
  /// **'Post as separate entry'**
  String get csvAddSeparately;

  /// No description provided for @csvBatchCounts.
  ///
  /// In en, this message translates to:
  /// **'{added} added · {matched} matched'**
  String csvBatchCounts(int added, int matched);

  /// No description provided for @csvNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No CSV import batches yet.'**
  String get csvNoHistory;

  /// No description provided for @csvBatchDetails.
  ///
  /// In en, this message translates to:
  /// **'Import batch details'**
  String get csvBatchDetails;

  /// No description provided for @csvUndone.
  ///
  /// In en, this message translates to:
  /// **'Undone'**
  String get csvUndone;

  /// No description provided for @csvUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo batch'**
  String get csvUndo;

  /// No description provided for @csvConfirmUndo.
  ///
  /// In en, this message translates to:
  /// **'Remove the transactions created by this batch? Matched transactions will remain in the ledger.'**
  String get csvConfirmUndo;

  /// No description provided for @csvOriginalRow.
  ///
  /// In en, this message translates to:
  /// **'Original CSV row'**
  String get csvOriginalRow;

  /// No description provided for @csvLedgerId.
  ///
  /// In en, this message translates to:
  /// **'Ledger transaction ID'**
  String get csvLedgerId;

  /// No description provided for @csvEncoding.
  ///
  /// In en, this message translates to:
  /// **'Save the file as UTF-8 CSV.'**
  String get csvEncoding;

  /// No description provided for @csvTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Use a file of up to 2 MB and 500 data rows.'**
  String get csvTooLarge;

  /// No description provided for @csvEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data rows were found.'**
  String get csvEmpty;

  /// No description provided for @csvHeaders.
  ///
  /// In en, this message translates to:
  /// **'Use unique headers including type, amount, occurred_at, and account.'**
  String get csvHeaders;

  /// No description provided for @csvSyntax.
  ///
  /// In en, this message translates to:
  /// **'Check the quotation marks in the CSV.'**
  String get csvSyntax;

  /// No description provided for @csvColumns.
  ///
  /// In en, this message translates to:
  /// **'The column count differs from the header.'**
  String get csvColumns;

  /// No description provided for @csvTypeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use expense, income, transfer, borrowing, or repayment.'**
  String get csvTypeInvalid;

  /// No description provided for @csvAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use a positive decimal amount with the currency’s supported precision.'**
  String get csvAmountInvalid;

  /// No description provided for @csvDateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use a valid ISO 8601 date or date and time.'**
  String get csvDateInvalid;

  /// No description provided for @csvCurrencyInvalid.
  ///
  /// In en, this message translates to:
  /// **'This currency is unsupported.'**
  String get csvCurrencyInvalid;

  /// No description provided for @csvSourceRequired.
  ///
  /// In en, this message translates to:
  /// **'Provide a source for each external ID.'**
  String get csvSourceRequired;

  /// No description provided for @csvAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Use a complete backup for advanced transaction details.'**
  String get csvAdvanced;

  /// No description provided for @csvReviewChanged.
  ///
  /// In en, this message translates to:
  /// **'The ledger or selection changed. Refresh and review the affected rows.'**
  String get csvReviewChanged;

  /// No description provided for @csvUndoModified.
  ///
  /// In en, this message translates to:
  /// **'A transaction in this batch was edited or deleted. The batch was kept intact.'**
  String get csvUndoModified;

  /// No description provided for @csvUndoLinked.
  ///
  /// In en, this message translates to:
  /// **'A transaction is linked to a refund, reversal, another batch, a repayment, or funds later used. The batch was kept intact.'**
  String get csvUndoLinked;

  /// No description provided for @csvBatchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This batch is unavailable.'**
  String get csvBatchUnavailable;

  /// No description provided for @csvOperationFailed.
  ///
  /// In en, this message translates to:
  /// **'The CSV operation failed.'**
  String get csvOperationFailed;

  /// No description provided for @csvBackupConflict.
  ///
  /// In en, this message translates to:
  /// **'The backup contains invalid or conflicting CSV import batches.'**
  String get csvBackupConflict;

  /// No description provided for @backupImportBatchCount.
  ///
  /// In en, this message translates to:
  /// **'CSV import batches {count}'**
  String backupImportBatchCount(int count);

  /// No description provided for @importCategoryRules.
  ///
  /// In en, this message translates to:
  /// **'Import category rules'**
  String get importCategoryRules;

  /// No description provided for @importRuleInstructions.
  ///
  /// In en, this message translates to:
  /// **'Combine conditions to suggest categories. Review suggestions before posting.'**
  String get importRuleInstructions;

  /// No description provided for @importRuleEmpty.
  ///
  /// In en, this message translates to:
  /// **'No rules yet. Add conditions and choose a category.'**
  String get importRuleEmpty;

  /// No description provided for @importRuleAdd.
  ///
  /// In en, this message translates to:
  /// **'Add rule'**
  String get importRuleAdd;

  /// No description provided for @importRuleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit rule'**
  String get importRuleEdit;

  /// No description provided for @importRuleDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete this rule?'**
  String get importRuleDelete;

  /// No description provided for @importRuleFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Match field'**
  String get importRuleFieldLabel;

  /// No description provided for @importRuleKeyword.
  ///
  /// In en, this message translates to:
  /// **'Match text'**
  String get importRuleKeyword;

  /// No description provided for @importRulePriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get importRulePriority;

  /// No description provided for @importRulePriorityHint.
  ///
  /// In en, this message translates to:
  /// **'Smaller numbers take priority.'**
  String get importRulePriorityHint;

  /// No description provided for @importRulePriorityValue.
  ///
  /// In en, this message translates to:
  /// **'Priority {value}'**
  String importRulePriorityValue(int value);

  /// No description provided for @importRuleEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get importRuleEnabled;

  /// No description provided for @importRuleDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get importRuleDisabled;

  /// No description provided for @importRuleInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the conditions, currency precision, and priority from 0 to 9999.'**
  String get importRuleInvalid;

  /// No description provided for @importRuleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Category unavailable'**
  String get importRuleUnavailable;

  /// No description provided for @importRuleMerchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant or counterparty'**
  String get importRuleMerchant;

  /// No description provided for @importRuleDescription.
  ///
  /// In en, this message translates to:
  /// **'Description or note'**
  String get importRuleDescription;

  /// No description provided for @importRulePayment.
  ///
  /// In en, this message translates to:
  /// **'Payment channel'**
  String get importRulePayment;

  /// No description provided for @importRuleSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get importRuleSource;

  /// No description provided for @importRuleSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested by rule “{keyword}”'**
  String importRuleSuggested(String keyword);

  /// No description provided for @importRuleConflict.
  ///
  /// In en, this message translates to:
  /// **'Rules disagree. Choose a category.'**
  String get importRuleConflict;

  /// No description provided for @importRulesBackupConflict.
  ///
  /// In en, this message translates to:
  /// **'The backup has invalid or conflicting import rules.'**
  String get importRulesBackupConflict;

  /// No description provided for @statementSkipped.
  ///
  /// In en, this message translates to:
  /// **'Review the platform status and type. This row cannot be posted as ordinary income or spending.'**
  String get statementSkipped;

  /// No description provided for @statementWorkbookInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use an unencrypted XLSX workbook with one supported statement sheet.'**
  String get statementWorkbookInvalid;

  /// No description provided for @csvCopyScreenshotPrompt.
  ///
  /// In en, this message translates to:
  /// **'Copy screenshot transcription prompt'**
  String get csvCopyScreenshotPrompt;

  /// No description provided for @csvScreenshotPromptCopied.
  ///
  /// In en, this message translates to:
  /// **'Screenshot transcription prompt copied'**
  String get csvScreenshotPromptCopied;

  /// No description provided for @csvScreenshotPrompt.
  ///
  /// In en, this message translates to:
  /// **'Transcribe only clearly visible completed income and expense entries from my screenshots. Return CSV only, without a Markdown fence. Use this header verbatim:\ntype,amount,occurred_at,account,category,note,currency_code,merchant,description,payment_channel,source,external_id\nUse expense or income, a positive amount, and an ISO 8601 date or timestamp. Leave unknown fields blank. Do not infer dates, totals, or transaction IDs. Only include an external ID if the screenshot shows the actual transaction ID and its source. Keep refunds, transfers, repayments, and pending items separate from ordinary income and expenses. Omit names of private individuals, account numbers, and card numbers. Quote fields containing commas, double quotes, or line breaks and escape double quotes by doubling them.'**
  String get csvScreenshotPrompt;

  /// No description provided for @spendingPlanBackupConflict.
  ///
  /// In en, this message translates to:
  /// **'The backup has invalid or conflicting budgets or allowances.'**
  String get spendingPlanBackupConflict;

  /// No description provided for @spendingPlans.
  ///
  /// In en, this message translates to:
  /// **'Budgets & allowances'**
  String get spendingPlans;

  /// No description provided for @addBudget.
  ///
  /// In en, this message translates to:
  /// **'Add budget'**
  String get addBudget;

  /// No description provided for @addAllowance.
  ///
  /// In en, this message translates to:
  /// **'Add allowance'**
  String get addAllowance;

  /// No description provided for @spendingPlansEmpty.
  ///
  /// In en, this message translates to:
  /// **'Create a budget or track an allowance for an entrusted account.'**
  String get spendingPlansEmpty;

  /// No description provided for @spendingPlansLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load budgets and allowances.'**
  String get spendingPlansLoadFailed;

  /// No description provided for @spendingPlanScope.
  ///
  /// In en, this message translates to:
  /// **'Spending scope'**
  String get spendingPlanScope;

  /// No description provided for @spendingPlanAllowance.
  ///
  /// In en, this message translates to:
  /// **'External allowance'**
  String get spendingPlanAllowance;

  /// No description provided for @spendingPlanNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'No eligible account is available.'**
  String get spendingPlanNoAccounts;

  /// No description provided for @spendingPlanNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No expense category is available.'**
  String get spendingPlanNoCategories;

  /// No description provided for @spendingPlanMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get spendingPlanMonthly;

  /// No description provided for @spendingPlanFixedPeriod.
  ///
  /// In en, this message translates to:
  /// **'Fixed date range'**
  String get spendingPlanFixedPeriod;

  /// No description provided for @spendingPlanStart.
  ///
  /// In en, this message translates to:
  /// **'First day'**
  String get spendingPlanStart;

  /// No description provided for @spendingPlanEnd.
  ///
  /// In en, this message translates to:
  /// **'Last day'**
  String get spendingPlanEnd;

  /// No description provided for @spendingPlanMonthlyHint.
  ///
  /// In en, this message translates to:
  /// **'Each month resets on the first cycle’s day, or the last day of a shorter month.'**
  String get spendingPlanMonthlyHint;

  /// No description provided for @spendingPlanRollover.
  ///
  /// In en, this message translates to:
  /// **'Carry over unused amount'**
  String get spendingPlanRollover;

  /// No description provided for @spendingPlanLimit.
  ///
  /// In en, this message translates to:
  /// **'Period limit'**
  String get spendingPlanLimit;

  /// No description provided for @spendingPlanCarried.
  ///
  /// In en, this message translates to:
  /// **'Carried over'**
  String get spendingPlanCarried;

  /// No description provided for @spendingPlanUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get spendingPlanUsed;

  /// No description provided for @spendingPlanRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get spendingPlanRemaining;

  /// No description provided for @spendingPlanProjected.
  ///
  /// In en, this message translates to:
  /// **'Projected spending at current pace'**
  String get spendingPlanProjected;

  /// No description provided for @spendingPlanOverLimit.
  ///
  /// In en, this message translates to:
  /// **'Over limit'**
  String get spendingPlanOverLimit;

  /// No description provided for @spendingPlanChangeLimit.
  ///
  /// In en, this message translates to:
  /// **'Change period limit'**
  String get spendingPlanChangeLimit;

  /// No description provided for @spendingPlanOngoing.
  ///
  /// In en, this message translates to:
  /// **'Apply to this and later months'**
  String get spendingPlanOngoing;

  /// No description provided for @spendingPlanLimitHistory.
  ///
  /// In en, this message translates to:
  /// **'Limit changes'**
  String get spendingPlanLimitHistory;

  /// No description provided for @spendingPlanSinglePeriod.
  ///
  /// In en, this message translates to:
  /// **'This period only'**
  String get spendingPlanSinglePeriod;

  /// No description provided for @spendingPlanFromPeriod.
  ///
  /// In en, this message translates to:
  /// **'This period onward'**
  String get spendingPlanFromPeriod;

  /// No description provided for @spendingPlanPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous period'**
  String get spendingPlanPrevious;

  /// No description provided for @spendingPlanNext.
  ///
  /// In en, this message translates to:
  /// **'Next period'**
  String get spendingPlanNext;

  /// No description provided for @spendingPlanNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No posted spending in this period.'**
  String get spendingPlanNoActivity;

  /// No description provided for @spendingPlanArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get spendingPlanArchived;

  /// No description provided for @spendingPlanReactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get spendingPlanReactivate;

  /// No description provided for @spendingPlanInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the dates, amount, and selected category or account. An entrusted account can have one active allowance.'**
  String get spendingPlanInvalid;

  /// No description provided for @backupSpendingPlanCount.
  ///
  /// In en, this message translates to:
  /// **'Budgets & allowances {count}'**
  String backupSpendingPlanCount(int count);

  /// No description provided for @recurringPlans.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions & recurring plans'**
  String get recurringPlans;

  /// No description provided for @recurringAddPlan.
  ///
  /// In en, this message translates to:
  /// **'Add recurring plan'**
  String get recurringAddPlan;

  /// No description provided for @recurringEmpty.
  ///
  /// In en, this message translates to:
  /// **'Create a subscription or another repeating expense or income.'**
  String get recurringEmpty;

  /// No description provided for @recurringLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load recurring plans.'**
  String get recurringLoadFailed;

  /// No description provided for @recurringSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get recurringSubscription;

  /// No description provided for @recurringPlanType.
  ///
  /// In en, this message translates to:
  /// **'Plan type'**
  String get recurringPlanType;

  /// No description provided for @recurringCadence.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get recurringCadence;

  /// No description provided for @recurringDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get recurringDaily;

  /// No description provided for @recurringWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get recurringWeekly;

  /// No description provided for @recurringQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get recurringQuarterly;

  /// No description provided for @recurringYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get recurringYearly;

  /// No description provided for @recurringCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom days'**
  String get recurringCustom;

  /// No description provided for @recurringIntervalDays.
  ///
  /// In en, this message translates to:
  /// **'Days between occurrences'**
  String get recurringIntervalDays;

  /// No description provided for @recurringFirstDue.
  ///
  /// In en, this message translates to:
  /// **'First due date'**
  String get recurringFirstDue;

  /// No description provided for @recurringNextDue.
  ///
  /// In en, this message translates to:
  /// **'Next due date'**
  String get recurringNextDue;

  /// No description provided for @recurringExpectedAmount.
  ///
  /// In en, this message translates to:
  /// **'Expected amount'**
  String get recurringExpectedAmount;

  /// No description provided for @recurringChangeAmount.
  ///
  /// In en, this message translates to:
  /// **'Change expected amount'**
  String get recurringChangeAmount;

  /// No description provided for @recurringPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get recurringPause;

  /// No description provided for @recurringResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get recurringResume;

  /// No description provided for @recurringPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get recurringPaused;

  /// No description provided for @recurringOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get recurringOverdue;

  /// No description provided for @recurringScheduleEnded.
  ///
  /// In en, this message translates to:
  /// **'No more dates'**
  String get recurringScheduleEnded;

  /// No description provided for @recurringConfirmPosting.
  ///
  /// In en, this message translates to:
  /// **'Review & post'**
  String get recurringConfirmPosting;

  /// No description provided for @recurringPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm actual transaction'**
  String get recurringPostTitle;

  /// No description provided for @recurringActualAmount.
  ///
  /// In en, this message translates to:
  /// **'Actual amount'**
  String get recurringActualAmount;

  /// No description provided for @recurringActualDate.
  ///
  /// In en, this message translates to:
  /// **'Actual date'**
  String get recurringActualDate;

  /// No description provided for @recurringPost.
  ///
  /// In en, this message translates to:
  /// **'Confirm & post'**
  String get recurringPost;

  /// No description provided for @recurringLink.
  ///
  /// In en, this message translates to:
  /// **'Link an existing transaction'**
  String get recurringLink;

  /// No description provided for @recurringSearch.
  ///
  /// In en, this message translates to:
  /// **'Search note, date or amount'**
  String get recurringSearch;

  /// No description provided for @recurringNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No eligible posted transactions for this account and currency.'**
  String get recurringNoMatches;

  /// No description provided for @recurringHistory.
  ///
  /// In en, this message translates to:
  /// **'Linked transactions'**
  String get recurringHistory;

  /// No description provided for @recurringNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No cycles have been confirmed yet.'**
  String get recurringNoHistory;

  /// No description provided for @recurringUnavailableEntry.
  ///
  /// In en, this message translates to:
  /// **'Transaction unavailable'**
  String get recurringUnavailableEntry;

  /// No description provided for @recurringReversedEntry.
  ///
  /// In en, this message translates to:
  /// **'Reversed'**
  String get recurringReversedEntry;

  /// No description provided for @recurringChangedEntry.
  ///
  /// In en, this message translates to:
  /// **'Transaction details changed'**
  String get recurringChangedEntry;

  /// No description provided for @recurringUnavailableTarget.
  ///
  /// In en, this message translates to:
  /// **'The account or category is archived or unavailable.'**
  String get recurringUnavailableTarget;

  /// No description provided for @recurringInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the plan, amount and date.'**
  String get recurringInvalid;

  /// No description provided for @recurringStale.
  ///
  /// In en, this message translates to:
  /// **'This cycle was already processed or the plan changed. Review the current cycle.'**
  String get recurringStale;

  /// No description provided for @recurringIneligible.
  ///
  /// In en, this message translates to:
  /// **'This transaction can no longer be linked.'**
  String get recurringIneligible;

  /// No description provided for @recurringAlreadyLinked.
  ///
  /// In en, this message translates to:
  /// **'This transaction is already linked to a cycle.'**
  String get recurringAlreadyLinked;

  /// No description provided for @recurringBackupConflict.
  ///
  /// In en, this message translates to:
  /// **'The backup has invalid or conflicting recurring plans or transaction links.'**
  String get recurringBackupConflict;

  /// No description provided for @backupRecurringPlanCount.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions & recurring plans {count}'**
  String backupRecurringPlanCount(int count);

  /// No description provided for @debtContracts.
  ///
  /// In en, this message translates to:
  /// **'Debt & receivable contracts'**
  String get debtContracts;

  /// No description provided for @debtAddContract.
  ///
  /// In en, this message translates to:
  /// **'Add contract'**
  String get debtAddContract;

  /// No description provided for @debtEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add a contract for a debt or receivable account.'**
  String get debtEmpty;

  /// No description provided for @debtLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load contracts.'**
  String get debtLoadFailed;

  /// No description provided for @debtCounterparty.
  ///
  /// In en, this message translates to:
  /// **'Counterparty'**
  String get debtCounterparty;

  /// No description provided for @debtOriginalPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Original principal'**
  String get debtOriginalPrincipal;

  /// No description provided for @debtOutstandingPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Outstanding principal'**
  String get debtOutstandingPrincipal;

  /// No description provided for @debtExpectedInterest.
  ///
  /// In en, this message translates to:
  /// **'Agreed interest'**
  String get debtExpectedInterest;

  /// No description provided for @debtDueDate.
  ///
  /// In en, this message translates to:
  /// **'Contract due date'**
  String get debtDueDate;

  /// No description provided for @debtSchedule.
  ///
  /// In en, this message translates to:
  /// **'Repayment schedule'**
  String get debtSchedule;

  /// No description provided for @debtAddInstallment.
  ///
  /// In en, this message translates to:
  /// **'Add installment'**
  String get debtAddInstallment;

  /// No description provided for @debtInstallment.
  ///
  /// In en, this message translates to:
  /// **'Installment'**
  String get debtInstallment;

  /// No description provided for @debtInstallmentDate.
  ///
  /// In en, this message translates to:
  /// **'Installment due date'**
  String get debtInstallmentDate;

  /// No description provided for @debtScheduleDefault.
  ///
  /// In en, this message translates to:
  /// **'Without installments, the full amount is due on the contract date.'**
  String get debtScheduleDefault;

  /// No description provided for @debtScheduleInvalid.
  ///
  /// In en, this message translates to:
  /// **'Installment dates must be distinct and within the contract term. Totals must match the agreed principal and interest.'**
  String get debtScheduleInvalid;

  /// No description provided for @debtPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get debtPrincipal;

  /// No description provided for @debtRemainingPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Principal awaiting allocation'**
  String get debtRemainingPrincipal;

  /// No description provided for @debtRemainingInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest awaiting allocation'**
  String get debtRemainingInterest;

  /// No description provided for @debtCleared.
  ///
  /// In en, this message translates to:
  /// **'Principal cleared'**
  String get debtCleared;

  /// No description provided for @debtBalanceReview.
  ///
  /// In en, this message translates to:
  /// **'Review ledger balance'**
  String get debtBalanceReview;

  /// No description provided for @debtOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue installment'**
  String get debtOverdue;

  /// No description provided for @debtAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Each contract uses one debt or receivable account to read the outstanding principal.'**
  String get debtAccountHint;

  /// No description provided for @debtNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'Create a debt or receivable account to get started.'**
  String get debtNoAccounts;

  /// No description provided for @debtAddLiabilityAccount.
  ///
  /// In en, this message translates to:
  /// **'Add debt account'**
  String get debtAddLiabilityAccount;

  /// No description provided for @debtAddReceivableAccount.
  ///
  /// In en, this message translates to:
  /// **'Add receivable account'**
  String get debtAddReceivableAccount;

  /// No description provided for @debtInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the account, dates, and amounts.'**
  String get debtInvalid;

  /// No description provided for @debtAccountInUse.
  ///
  /// In en, this message translates to:
  /// **'This account already has a contract.'**
  String get debtAccountInUse;

  /// No description provided for @debtLinkRepayment.
  ///
  /// In en, this message translates to:
  /// **'Link a repayment'**
  String get debtLinkRepayment;

  /// No description provided for @debtLinkCollection.
  ///
  /// In en, this message translates to:
  /// **'Link a collection'**
  String get debtLinkCollection;

  /// No description provided for @debtLinkInterest.
  ///
  /// In en, this message translates to:
  /// **'Link interest income'**
  String get debtLinkInterest;

  /// No description provided for @debtNoPayments.
  ///
  /// In en, this message translates to:
  /// **'No eligible unlinked payment. Record the actual transaction in Transactions first.'**
  String get debtNoPayments;

  /// No description provided for @debtHistory.
  ///
  /// In en, this message translates to:
  /// **'Settlement history'**
  String get debtHistory;

  /// No description provided for @debtNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No transactions have been linked.'**
  String get debtNoHistory;

  /// No description provided for @debtUnlink.
  ///
  /// In en, this message translates to:
  /// **'Undo allocation'**
  String get debtUnlink;

  /// No description provided for @debtUnlinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Undo this allocation?'**
  String get debtUnlinkTitle;

  /// No description provided for @debtUnlinkMessage.
  ///
  /// In en, this message translates to:
  /// **'The transaction stays in the ledger. The scheduled amounts will be recalculated.'**
  String get debtUnlinkMessage;

  /// No description provided for @debtVoidedLink.
  ///
  /// In en, this message translates to:
  /// **'Allocation undone'**
  String get debtVoidedLink;

  /// No description provided for @debtInvalidatedLink.
  ///
  /// In en, this message translates to:
  /// **'Transaction changed, was reversed, or is unavailable'**
  String get debtInvalidatedLink;

  /// No description provided for @debtIneligible.
  ///
  /// In en, this message translates to:
  /// **'The transaction is unavailable or no longer matches this account and currency.'**
  String get debtIneligible;

  /// No description provided for @debtConflict.
  ///
  /// In en, this message translates to:
  /// **'This transaction is already linked.'**
  String get debtConflict;

  /// No description provided for @debtUnlinkedPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Posted principal to link'**
  String get debtUnlinkedPrincipal;

  /// No description provided for @debtBackupConflict.
  ///
  /// In en, this message translates to:
  /// **'The backup has invalid or conflicting debt contracts or settlements.'**
  String get debtBackupConflict;

  /// No description provided for @backupDebtContractCount.
  ///
  /// In en, this message translates to:
  /// **'Debt & receivable contracts {count}'**
  String backupDebtContractCount(int count);

  /// No description provided for @savingsGoals.
  ///
  /// In en, this message translates to:
  /// **'Savings goals'**
  String get savingsGoals;

  /// No description provided for @savingsAddGoal.
  ///
  /// In en, this message translates to:
  /// **'Add savings goal'**
  String get savingsAddGoal;

  /// No description provided for @savingsEditGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit savings goal'**
  String get savingsEditGoal;

  /// No description provided for @savingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Create a goal for money you want to set aside.'**
  String get savingsEmpty;

  /// No description provided for @savingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load savings goals.'**
  String get savingsLoadFailed;

  /// No description provided for @savingsNoAccounts.
  ///
  /// In en, this message translates to:
  /// **'A personal cash, bank, wallet, or savings account is required.'**
  String get savingsNoAccounts;

  /// No description provided for @savingsTarget.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get savingsTarget;

  /// No description provided for @savingsTargetOn.
  ///
  /// In en, this message translates to:
  /// **'Target date'**
  String get savingsTargetOn;

  /// No description provided for @savingsNoDate.
  ///
  /// In en, this message translates to:
  /// **'No target date'**
  String get savingsNoDate;

  /// No description provided for @savingsClearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear target date'**
  String get savingsClearDate;

  /// No description provided for @savingsPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get savingsPriority;

  /// No description provided for @savingsPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get savingsPriorityHigh;

  /// No description provided for @savingsPriorityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get savingsPriorityNormal;

  /// No description provided for @savingsPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get savingsPriorityLow;

  /// No description provided for @savingsAllocated.
  ///
  /// In en, this message translates to:
  /// **'Allocated to goal'**
  String get savingsAllocated;

  /// No description provided for @savingsReserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved funds'**
  String get savingsReserved;

  /// No description provided for @savingsUnallocated.
  ///
  /// In en, this message translates to:
  /// **'Unallocated funds'**
  String get savingsUnallocated;

  /// No description provided for @savingsShortfall.
  ///
  /// In en, this message translates to:
  /// **'Allocation shortfall'**
  String get savingsShortfall;

  /// No description provided for @savingsReached.
  ///
  /// In en, this message translates to:
  /// **'Allocation target reached'**
  String get savingsReached;

  /// No description provided for @savingsReserve.
  ///
  /// In en, this message translates to:
  /// **'Reserve funds'**
  String get savingsReserve;

  /// No description provided for @savingsRelease.
  ///
  /// In en, this message translates to:
  /// **'Release funds'**
  String get savingsRelease;

  /// No description provided for @savingsHistory.
  ///
  /// In en, this message translates to:
  /// **'Allocation history'**
  String get savingsHistory;

  /// No description provided for @savingsNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No funds have been reserved or released.'**
  String get savingsNoHistory;

  /// No description provided for @savingsAccountArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived account. Reserved funds can still be released.'**
  String get savingsAccountArchived;

  /// No description provided for @savingsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the goal, account and amount.'**
  String get savingsInvalid;

  /// No description provided for @savingsNotEnoughUnallocated.
  ///
  /// In en, this message translates to:
  /// **'This amount exceeds the account’s unallocated funds.'**
  String get savingsNotEnoughUnallocated;

  /// No description provided for @savingsNotEnoughReserved.
  ///
  /// In en, this message translates to:
  /// **'This amount exceeds the funds reserved for this goal.'**
  String get savingsNotEnoughReserved;

  /// No description provided for @savingsBackupConflict.
  ///
  /// In en, this message translates to:
  /// **'The backup has invalid or conflicting savings goals or allocations.'**
  String get savingsBackupConflict;

  /// No description provided for @backupSavingsGoalCount.
  ///
  /// In en, this message translates to:
  /// **'Savings goals {count}'**
  String backupSavingsGoalCount(int count);

  /// No description provided for @cashForecast.
  ///
  /// In en, this message translates to:
  /// **'Cash flow forecast'**
  String get cashForecast;

  /// No description provided for @cashForecastReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the cash flow forecast.'**
  String get cashForecastReadFailed;

  /// No description provided for @forecastRangeDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String forecastRangeDays(int days);

  /// No description provided for @forecastPostedBalance.
  ///
  /// In en, this message translates to:
  /// **'Posted cash through today'**
  String get forecastPostedBalance;

  /// No description provided for @forecastClosingBalance.
  ///
  /// In en, this message translates to:
  /// **'Projected closing balance'**
  String get forecastClosingBalance;

  /// No description provided for @forecastPeakShortfall.
  ///
  /// In en, this message translates to:
  /// **'Largest projected shortfall'**
  String get forecastPeakShortfall;

  /// No description provided for @forecastFirstShortfall.
  ///
  /// In en, this message translates to:
  /// **'First shortfall {date}'**
  String forecastFirstShortfall(String date);

  /// No description provided for @forecastNoShortfall.
  ///
  /// In en, this message translates to:
  /// **'No projected shortfall'**
  String get forecastNoShortfall;

  /// No description provided for @forecastBalanceOverTime.
  ///
  /// In en, this message translates to:
  /// **'Projected balance by date'**
  String get forecastBalanceOverTime;

  /// No description provided for @forecastDailyClosing.
  ///
  /// In en, this message translates to:
  /// **'Projected day-end balance'**
  String get forecastDailyClosing;

  /// No description provided for @forecastCashMovements.
  ///
  /// In en, this message translates to:
  /// **'Cash flow timeline'**
  String get forecastCashMovements;

  /// No description provided for @forecastNoMovements.
  ///
  /// In en, this message translates to:
  /// **'No cash movements scheduled in this range.'**
  String get forecastNoMovements;

  /// No description provided for @forecastFuturePosted.
  ///
  /// In en, this message translates to:
  /// **'Posted · future date'**
  String get forecastFuturePosted;

  /// No description provided for @forecastScheduled.
  ///
  /// In en, this message translates to:
  /// **'Forecast · {source}'**
  String forecastScheduled(String source);

  /// No description provided for @forecastRecurringIncome.
  ///
  /// In en, this message translates to:
  /// **'Recurring income'**
  String get forecastRecurringIncome;

  /// No description provided for @forecastRecurringExpense.
  ///
  /// In en, this message translates to:
  /// **'Recurring expense'**
  String get forecastRecurringExpense;

  /// No description provided for @forecastSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription renewal'**
  String get forecastSubscription;

  /// No description provided for @forecastDebtRepayment.
  ///
  /// In en, this message translates to:
  /// **'Debt repayment'**
  String get forecastDebtRepayment;

  /// No description provided for @forecastReceivableCollection.
  ///
  /// In en, this message translates to:
  /// **'Receivable collection'**
  String get forecastReceivableCollection;

  /// No description provided for @forecastOverdueSince.
  ///
  /// In en, this message translates to:
  /// **'Originally due {date}'**
  String forecastOverdueSince(String date);

  /// No description provided for @forecastOverdueCycles.
  ///
  /// In en, this message translates to:
  /// **'{count} overdue cycles'**
  String forecastOverdueCycles(int count);

  /// No description provided for @forecastUncertainInflow.
  ///
  /// In en, this message translates to:
  /// **'Date unconfirmed · excluded from balance'**
  String get forecastUncertainInflow;

  /// No description provided for @forecastUnscheduledPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Principal with no scheduled date'**
  String get forecastUnscheduledPrincipal;

  /// No description provided for @forecastAssumptions.
  ///
  /// In en, this message translates to:
  /// **'What is included'**
  String get forecastAssumptions;

  /// No description provided for @forecastAssumptionsText.
  ///
  /// In en, this message translates to:
  /// **'Includes personal cash, bank, wallet and savings balances in the selected currency. Debt payments and collections use that currency’s cash. Overdue outflows are placed on today; overdue inflows wait for a confirmed date. Pending ledger entries are excluded. Each daily figure is an end-of-day balance. Review recurring plans to link any payments you already recorded.'**
  String get forecastAssumptionsText;

  /// No description provided for @ledgerFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get ledgerFilters;

  /// No description provided for @ledgerFiltersActive.
  ///
  /// In en, this message translates to:
  /// **'Filters applied'**
  String get ledgerFiltersActive;

  /// No description provided for @ledgerFilterFunding.
  ///
  /// In en, this message translates to:
  /// **'Funding source'**
  String get ledgerFilterFunding;

  /// No description provided for @ledgerFilterFundingPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personally borne'**
  String get ledgerFilterFundingPersonal;

  /// No description provided for @ledgerFilterThirdParty.
  ///
  /// In en, this message translates to:
  /// **'Paid by others, due back'**
  String get ledgerFilterThirdParty;

  /// No description provided for @ledgerFilterUnknownFunding.
  ///
  /// In en, this message translates to:
  /// **'Funding to review'**
  String get ledgerFilterUnknownFunding;

  /// No description provided for @ledgerFilterAllCurrencies.
  ///
  /// In en, this message translates to:
  /// **'All currencies'**
  String get ledgerFilterAllCurrencies;

  /// No description provided for @ledgerFilterAllAccounts.
  ///
  /// In en, this message translates to:
  /// **'All accounts'**
  String get ledgerFilterAllAccounts;

  /// No description provided for @ledgerFilterAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get ledgerFilterAllCategories;

  /// No description provided for @ledgerFilterAllFunding.
  ///
  /// In en, this message translates to:
  /// **'All funding sources'**
  String get ledgerFilterAllFunding;

  /// No description provided for @ledgerFilterUseReportPeriod.
  ///
  /// In en, this message translates to:
  /// **'Use report period'**
  String get ledgerFilterUseReportPeriod;

  /// No description provided for @ledgerFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get ledgerFilterClear;

  /// No description provided for @ledgerFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get ledgerFilterApply;

  /// No description provided for @ledgerFilterNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No transactions match these filters.'**
  String get ledgerFilterNoMatches;

  /// No description provided for @ledgerFilterMatched.
  ///
  /// In en, this message translates to:
  /// **'{count} matching transactions'**
  String ledgerFilterMatched(int count);

  /// No description provided for @ledgerFilterTotals.
  ///
  /// In en, this message translates to:
  /// **'Filtered posted totals'**
  String get ledgerFilterTotals;

  /// No description provided for @ledgerFilterAllocationHint.
  ///
  /// In en, this message translates to:
  /// **'Split payments and categories use the recorded shares. When both are split, the app allocates proportionally to the smallest currency unit. Linked advances contribute cash flow for the account, outside spending categories.'**
  String get ledgerFilterAllocationHint;

  /// No description provided for @ledgerFilterAccountCashFlow.
  ///
  /// In en, this message translates to:
  /// **'Cash movements by account'**
  String get ledgerFilterAccountCashFlow;

  /// No description provided for @ledgerFilterAccountCashFlowHint.
  ///
  /// In en, this message translates to:
  /// **'Includes movements between your own accounts. Ledger adjustments are reflected in balances.'**
  String get ledgerFilterAccountCashFlowHint;

  /// No description provided for @ledgerFilterAccountAnalysis.
  ///
  /// In en, this message translates to:
  /// **'View account activity'**
  String get ledgerFilterAccountAnalysis;

  /// No description provided for @ledgerFilterAccountGroup.
  ///
  /// In en, this message translates to:
  /// **'Account group'**
  String get ledgerFilterAccountGroup;

  /// No description provided for @ledgerFilterAllGroups.
  ///
  /// In en, this message translates to:
  /// **'All account groups'**
  String get ledgerFilterAllGroups;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @planningTab.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get planningTab;

  /// No description provided for @homeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the financial overview.'**
  String get homeLoadFailed;

  /// No description provided for @availableFunds.
  ///
  /// In en, this message translates to:
  /// **'Available funds'**
  String get availableFunds;

  /// No description provided for @availableFundsHint.
  ///
  /// In en, this message translates to:
  /// **'Personal cash through today, after savings reservations in each account.'**
  String get availableFundsHint;

  /// No description provided for @homeBudgetRemaining.
  ///
  /// In en, this message translates to:
  /// **'Budget remaining'**
  String get homeBudgetRemaining;

  /// No description provided for @homeNoBudgets.
  ///
  /// In en, this message translates to:
  /// **'No active budgets in this currency.'**
  String get homeNoBudgets;

  /// No description provided for @homeObligations.
  ///
  /// In en, this message translates to:
  /// **'Cash obligations in the next 7 days'**
  String get homeObligations;

  /// No description provided for @homeNoObligations.
  ///
  /// In en, this message translates to:
  /// **'No scheduled cash payments in this currency.'**
  String get homeNoObligations;

  /// No description provided for @homeReconciliation.
  ///
  /// In en, this message translates to:
  /// **'Reconciliation to review'**
  String get homeReconciliation;

  /// No description provided for @homeNoReconciliation.
  ///
  /// In en, this message translates to:
  /// **'No outstanding balance differences.'**
  String get homeNoReconciliation;

  /// No description provided for @paymentChannel.
  ///
  /// In en, this message translates to:
  /// **'Payment channel'**
  String get paymentChannel;

  /// No description provided for @allPaymentChannels.
  ///
  /// In en, this message translates to:
  /// **'All payment channels'**
  String get allPaymentChannels;

  /// No description provided for @transactionCounterparty.
  ///
  /// In en, this message translates to:
  /// **'Counterparty'**
  String get transactionCounterparty;

  /// No description provided for @allCounterparties.
  ///
  /// In en, this message translates to:
  /// **'All counterparties'**
  String get allCounterparties;

  /// No description provided for @transactionSources.
  ///
  /// In en, this message translates to:
  /// **'Original statement'**
  String get transactionSources;

  /// No description provided for @importedRowFields.
  ///
  /// In en, this message translates to:
  /// **'Imported fields'**
  String get importedRowFields;

  /// No description provided for @historicalAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Historical analysis'**
  String get historicalAnalysis;

  /// No description provided for @reportTransactions.
  ///
  /// In en, this message translates to:
  /// **'View matching transactions'**
  String get reportTransactions;

  /// No description provided for @historyFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Activity uses the report filters across each period. Net worth uses the currency and account selection.'**
  String get historyFilterHint;

  /// No description provided for @historyMethod.
  ///
  /// In en, this message translates to:
  /// **'Net worth at period end is shown in the original currency. The current period runs through today.'**
  String get historyMethod;

  /// No description provided for @historyNetWorth.
  ///
  /// In en, this message translates to:
  /// **'Period-end net worth'**
  String get historyNetWorth;

  /// No description provided for @historyThroughDate.
  ///
  /// In en, this message translates to:
  /// **'Through {date}'**
  String historyThroughDate(String date);

  /// No description provided for @historyPreviousDifference.
  ///
  /// In en, this message translates to:
  /// **'Vs previous period {amount}'**
  String historyPreviousDifference(String amount);

  /// No description provided for @exportFinancialReport.
  ///
  /// In en, this message translates to:
  /// **'Export financial report'**
  String get exportFinancialReport;

  /// No description provided for @reportIncludeTransactions.
  ///
  /// In en, this message translates to:
  /// **'Include matching transactions'**
  String get reportIncludeTransactions;

  /// No description provided for @reportIncludeSensitive.
  ///
  /// In en, this message translates to:
  /// **'Include notes, payment channels and counterparties'**
  String get reportIncludeSensitive;

  /// No description provided for @reportExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the report. Try again.'**
  String get reportExportFailed;

  /// No description provided for @reportExportSaved.
  ///
  /// In en, this message translates to:
  /// **'Financial report saved'**
  String get reportExportSaved;

  /// No description provided for @reportFinancialPosition.
  ///
  /// In en, this message translates to:
  /// **'Assets and liabilities'**
  String get reportFinancialPosition;

  /// No description provided for @reportAssets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get reportAssets;

  /// No description provided for @reportLiabilities.
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get reportLiabilities;

  /// No description provided for @reportNetWorth.
  ///
  /// In en, this message translates to:
  /// **'Net worth'**
  String get reportNetWorth;

  /// No description provided for @reportOpeningToClosing.
  ///
  /// In en, this message translates to:
  /// **'Opening {opening} · Closing {closing}'**
  String reportOpeningToClosing(String opening, String closing);

  /// No description provided for @importRuleMatchMode.
  ///
  /// In en, this message translates to:
  /// **'Match mode'**
  String get importRuleMatchMode;

  /// No description provided for @importRuleMatchAll.
  ///
  /// In en, this message translates to:
  /// **'All conditions'**
  String get importRuleMatchAll;

  /// No description provided for @importRuleMatchAny.
  ///
  /// In en, this message translates to:
  /// **'Any condition'**
  String get importRuleMatchAny;

  /// No description provided for @importRuleContains.
  ///
  /// In en, this message translates to:
  /// **'Contains'**
  String get importRuleContains;

  /// No description provided for @importRuleEquals.
  ///
  /// In en, this message translates to:
  /// **'Equals'**
  String get importRuleEquals;

  /// No description provided for @importRuleStartsWith.
  ///
  /// In en, this message translates to:
  /// **'Starts with'**
  String get importRuleStartsWith;

  /// No description provided for @importRuleAtLeast.
  ///
  /// In en, this message translates to:
  /// **'At least'**
  String get importRuleAtLeast;

  /// No description provided for @importRuleAtMost.
  ///
  /// In en, this message translates to:
  /// **'At most'**
  String get importRuleAtMost;

  /// No description provided for @importRuleOperator.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get importRuleOperator;

  /// No description provided for @importRuleAddCondition.
  ///
  /// In en, this message translates to:
  /// **'Add condition'**
  String get importRuleAddCondition;

  /// No description provided for @importRuleRemoveCondition.
  ///
  /// In en, this message translates to:
  /// **'Remove condition'**
  String get importRuleRemoveCondition;

  /// No description provided for @importRuleTrial.
  ///
  /// In en, this message translates to:
  /// **'Try rules'**
  String get importRuleTrial;

  /// No description provided for @importRuleTrialHint.
  ///
  /// In en, this message translates to:
  /// **'Choose or paste a sample statement to see matching rules and category suggestions.'**
  String get importRuleTrialHint;

  /// No description provided for @importRuleDraftTrialHint.
  ///
  /// In en, this message translates to:
  /// **'The preview runs your draft alongside the other saved rules.'**
  String get importRuleDraftTrialHint;

  /// No description provided for @importRuleTrialSummary.
  ///
  /// In en, this message translates to:
  /// **'Rows {rows} · Suggestions {suggested} · Conflicts {conflicts}'**
  String importRuleTrialSummary(int rows, int suggested, int conflicts);

  /// No description provided for @importRuleTrialExplicit.
  ///
  /// In en, this message translates to:
  /// **'Source category · {category}'**
  String importRuleTrialExplicit(String category);

  /// No description provided for @importRuleTrialSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested category · {category}'**
  String importRuleTrialSuggested(String category);

  /// No description provided for @importRuleTrialNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No rule matched'**
  String get importRuleTrialNoMatch;

  /// No description provided for @importRuleTrialUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Category rules apply to income and expense rows.'**
  String get importRuleTrialUnsupported;

  /// No description provided for @importRuleTopPriority.
  ///
  /// In en, this message translates to:
  /// **'Highest priority'**
  String get importRuleTopPriority;

  /// No description provided for @importRuleDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get importRuleDraft;
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
