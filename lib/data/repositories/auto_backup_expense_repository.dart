import 'package:summa/core/money/money.dart';
import 'package:summa/data/backup/local_backup_store.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/categories/ledger_category.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/import_export/csv_import.dart';
import 'package:summa/domain/import_export/import_category_rule.dart';
import 'package:summa/domain/import_export/ledger_import.dart';
import 'package:summa/domain/planning/recurring_plan.dart';
import 'package:summa/domain/planning/spending_plan.dart';
import 'package:summa/domain/reconciliation/balance_checkpoint.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/transaction_terms.dart';
import 'package:summa/domain/transactions/expense_repository.dart';
import 'package:summa/domain/valuation/net_worth_valuation.dart';

class AutoBackupExpenseRepository implements ExpenseRepository {
  AutoBackupExpenseRepository(this._delegate, this._backupStore);

  final ExpenseRepository _delegate;
  final LocalBackupStore _backupStore;

  Future<void> _mutate(Future<void> Function() action) async {
    final path = await _backupStore.beginAutomaticBackup(
      await _delegate.createFullBackup(),
    );
    try {
      await action();
    } catch (_) {
      await _backupStore.rollBackAutomaticBackup(path);
      rethrow;
    }
    try {
      await _backupStore.commitAutomaticBackup(path);
    } catch (_) {
      // The ledger edit already succeeded; rotation maintenance must not make
      // the caller believe that the edit failed.
    }
  }

  @override
  Stream<List<LedgerRecord>> watchTransactions() =>
      _delegate.watchTransactions();

  @override
  Stream<List<LedgerAccount>> watchAccounts() => _delegate.watchAccounts();

  @override
  Stream<List<AccountBalance>> watchAccountBalances() =>
      _delegate.watchAccountBalances();

  @override
  Stream<List<LedgerCategory>> watchExpenseCategories() =>
      _delegate.watchExpenseCategories();

  @override
  Stream<List<LedgerCategory>> watchIncomeCategories() =>
      _delegate.watchIncomeCategories();

  @override
  Future<void> addExpense({
    required int amountMinor,
    required DateTime occurredAt,
    required String categoryId,
    required String accountId,
    required String note,
  }) => _mutate(
    () => _delegate.addExpense(
      amountMinor: amountMinor,
      occurredAt: occurredAt,
      categoryId: categoryId,
      accountId: accountId,
      note: note,
    ),
  );

  @override
  Future<void> updateExpense({
    required String id,
    required int amountMinor,
    required DateTime occurredAt,
    required String categoryId,
    required String accountId,
    required String note,
  }) => _mutate(
    () => _delegate.updateExpense(
      id: id,
      amountMinor: amountMinor,
      occurredAt: occurredAt,
      categoryId: categoryId,
      accountId: accountId,
      note: note,
    ),
  );

  @override
  Future<void> deleteTransaction(String id) =>
      _mutate(() => _delegate.deleteTransaction(id));

  @override
  Future<void> addTransaction({
    required LedgerTransactionType type,
    required int amountMinor,
    required DateTime occurredAt,
    required String accountId,
    String? targetAccountId,
    String? categoryId,
    List<AccountPayment>? payments,
    TransferSettlement? settlement,
    TransactionTerms terms = const TransactionTerms(),
    LedgerPostingStatus status = LedgerPostingStatus.posted,
    required String note,
  }) => _mutate(
    () => _delegate.addTransaction(
      type: type,
      amountMinor: amountMinor,
      occurredAt: occurredAt,
      accountId: accountId,
      targetAccountId: targetAccountId,
      categoryId: categoryId,
      payments: payments,
      settlement: settlement,
      terms: terms,
      status: status,
      note: note,
    ),
  );

  @override
  Future<void> updateTransaction({
    required String id,
    required LedgerTransactionType type,
    required int amountMinor,
    required DateTime occurredAt,
    required String accountId,
    String? targetAccountId,
    String? categoryId,
    List<AccountPayment>? payments,
    TransferSettlement? settlement,
    TransactionTerms? terms,
    required String note,
  }) => _mutate(
    () => _delegate.updateTransaction(
      id: id,
      type: type,
      amountMinor: amountMinor,
      occurredAt: occurredAt,
      accountId: accountId,
      targetAccountId: targetAccountId,
      categoryId: categoryId,
      payments: payments,
      settlement: settlement,
      terms: terms,
      note: note,
    ),
  );

  @override
  Future<void> postTransaction(String id) =>
      _mutate(() => _delegate.postTransaction(id));

  @override
  Future<void> reverseTransaction(String id, {required DateTime occurredAt}) =>
      _mutate(() => _delegate.reverseTransaction(id, occurredAt: occurredAt));

  @override
  Stream<List<BalanceCheckpoint>> watchBalanceCheckpoints(String accountId) =>
      _delegate.watchBalanceCheckpoints(accountId);

  @override
  Future<void> saveBalanceCheckpoint({
    required String accountId,
    required DateTime observedAt,
    required int actualMinor,
    required String note,
  }) => _mutate(
    () => _delegate.saveBalanceCheckpoint(
      accountId: accountId,
      observedAt: observedAt,
      actualMinor: actualMinor,
      note: note,
    ),
  );

  @override
  Future<void> adjustBalanceCheckpoint(
    String id, {
    required int expectedBookMinor,
  }) => _mutate(
    () => _delegate.adjustBalanceCheckpoint(
      id,
      expectedBookMinor: expectedBookMinor,
    ),
  );

  @override
  Future<void> voidBalanceCheckpoint(String id) =>
      _mutate(() => _delegate.voidBalanceCheckpoint(id));

  @override
  Future<void> recordBalanceAdjustment({
    required String accountId,
    required int amountMinor,
    required String note,
  }) => _mutate(
    () => _delegate.recordBalanceAdjustment(
      accountId: accountId,
      amountMinor: amountMinor,
      note: note,
    ),
  );

  @override
  Future<void> saveFamilyExpense({
    String? id,
    required int amountMinor,
    required String currencyCode,
    required DateTime occurredAt,
    required String categoryId,
    required String note,
    List<CategoryAmount> categories = const [],
    LedgerPostingStatus status = LedgerPostingStatus.posted,
  }) => _mutate(
    () => _delegate.saveFamilyExpense(
      id: id,
      amountMinor: amountMinor,
      currencyCode: currencyCode,
      occurredAt: occurredAt,
      categoryId: categoryId,
      note: note,
      categories: categories,
      status: status,
    ),
  );

  @override
  Future<void> saveRefund({
    String? id,
    required String originalId,
    required String accountId,
    required int amountMinor,
    required DateTime occurredAt,
    required String note,
    int? advanceCancellationMinor,
    LedgerPostingStatus status = LedgerPostingStatus.posted,
  }) => _mutate(
    () => _delegate.saveRefund(
      id: id,
      originalId: originalId,
      accountId: accountId,
      amountMinor: amountMinor,
      occurredAt: occurredAt,
      note: note,
      advanceCancellationMinor: advanceCancellationMinor,
      status: status,
    ),
  );

  @override
  Stream<List<ImportCategoryRule>> watchImportRules() =>
      _delegate.watchImportRules();

  @override
  Future<void> saveImportRule({
    String? id,
    required ImportRuleField field,
    required String keyword,
    required String categoryId,
    required int priority,
    required bool enabled,
  }) => _mutate(
    () => _delegate.saveImportRule(
      id: id,
      field: field,
      keyword: keyword,
      categoryId: categoryId,
      priority: priority,
      enabled: enabled,
    ),
  );

  @override
  Future<void> deleteImportRule(String id) =>
      _mutate(() => _delegate.deleteImportRule(id));

  @override
  Stream<List<SpendingPlan>> watchSpendingPlans() =>
      _delegate.watchSpendingPlans();

  @override
  Future<void> addSpendingPlan(SpendingPlanDraft draft) =>
      _mutate(() => _delegate.addSpendingPlan(draft));

  @override
  Future<void> setSpendingPlanLimit(String id, SpendingPlanLimit limit) =>
      _mutate(() => _delegate.setSpendingPlanLimit(id, limit));

  @override
  Future<void> setSpendingPlanArchived(String id, bool archived) =>
      _mutate(() => _delegate.setSpendingPlanArchived(id, archived));

  @override
  Stream<List<RecurringPlan>> watchRecurringPlans() =>
      _delegate.watchRecurringPlans();

  @override
  Future<void> addRecurringPlan(RecurringPlanDraft draft) =>
      _mutate(() => _delegate.addRecurringPlan(draft));

  @override
  Future<void> setRecurringPlanPaused(String id, bool paused) =>
      _mutate(() => _delegate.setRecurringPlanPaused(id, paused));

  @override
  Future<void> setRecurringPlanExpectedAmount(String id, int amountMinor) =>
      _mutate(() => _delegate.setRecurringPlanExpectedAmount(id, amountMinor));

  @override
  Future<void> confirmRecurringOccurrence(
    String id,
    int expectedIndex, {
    required int amountMinor,
    required DateTime occurredAt,
    required String note,
  }) => _mutate(
    () => _delegate.confirmRecurringOccurrence(
      id,
      expectedIndex,
      amountMinor: amountMinor,
      occurredAt: occurredAt,
      note: note,
    ),
  );

  @override
  Future<void> linkRecurringOccurrence(
    String id,
    int expectedIndex,
    String entryId,
  ) => _mutate(
    () => _delegate.linkRecurringOccurrence(id, expectedIndex, entryId),
  );

  @override
  Future<List<CsvReviewRow>> previewCsvImport(
    CsvImportFile file, {
    Map<int, CsvMapping> mappings = const {},
  }) => _delegate.previewCsvImport(file, mappings: mappings);

  @override
  Future<CsvImportResult> commitCsvImport(
    CsvImportFile file,
    List<CsvSelection> selections,
  ) async {
    late CsvImportResult result;
    await _mutate(
      () async => result = await _delegate.commitCsvImport(file, selections),
    );
    return result;
  }

  @override
  Stream<List<CsvBatchSummary>> watchCsvBatches() =>
      _delegate.watchCsvBatches();

  @override
  Future<List<CsvBatchItem>> readCsvBatchItems(String id) =>
      _delegate.readCsvBatchItems(id);

  @override
  Future<void> undoCsvImport(String id) =>
      _mutate(() => _delegate.undoCsvImport(id));

  @override
  Future<void> importTransactions(List<LedgerImportDraft> drafts) =>
      drafts.isEmpty
      ? Future.value()
      : _mutate(() => _delegate.importTransactions(drafts));

  @override
  Future<void> setCurrentBalance({
    required String accountId,
    required int amountMinor,
  }) => _mutate(
    () => _delegate.setCurrentBalance(
      accountId: accountId,
      amountMinor: amountMinor,
    ),
  );

  @override
  Future<void> addAccount({
    required String name,
    required AccountKind kind,
    required int currentBalanceMinor,
    String currencyCode = defaultCurrency,
  }) => _mutate(
    () => _delegate.addAccount(
      name: name,
      kind: kind,
      currentBalanceMinor: currentBalanceMinor,
      currencyCode: currencyCode,
    ),
  );

  @override
  Future<void> archiveAccount(String id) =>
      _mutate(() => _delegate.archiveAccount(id));

  @override
  Future<void> restoreDefaultAccounts() =>
      _mutate(_delegate.restoreDefaultAccounts);

  @override
  Future<void> addCategory({
    required LedgerTransactionType type,
    required String name,
    String? parentId,
  }) => _mutate(
    () => _delegate.addCategory(type: type, name: name, parentId: parentId),
  );

  @override
  Future<void> renameCategory({required String id, required String name}) =>
      _mutate(() => _delegate.renameCategory(id: id, name: name));

  @override
  Future<void> archiveCategory(String id) =>
      _mutate(() => _delegate.archiveCategory(id));

  @override
  Future<void> moveCategory(String id, {required bool moveUp}) =>
      _mutate(() => _delegate.moveCategory(id, moveUp: moveUp));

  @override
  Future<void> restoreDefaultCategories() =>
      _mutate(_delegate.restoreDefaultCategories);

  @override
  Stream<ValuationSettings> watchValuationSettings() =>
      _delegate.watchValuationSettings();

  @override
  Future<void> setValuationBaseCurrency(String baseCurrency) =>
      _mutate(() => _delegate.setValuationBaseCurrency(baseCurrency));

  @override
  Future<void> saveValuationRate({
    required String sourceCurrency,
    required String baseCurrency,
    required String rate,
  }) => _mutate(
    () => _delegate.saveValuationRate(
      sourceCurrency: sourceCurrency,
      baseCurrency: baseCurrency,
      rate: rate,
    ),
  );

  @override
  Future<void> removeValuationRate({
    required String sourceCurrency,
    required String baseCurrency,
  }) => _mutate(
    () => _delegate.removeValuationRate(
      sourceCurrency: sourceCurrency,
      baseCurrency: baseCurrency,
    ),
  );

  @override
  Future<String> createFullBackup() => _delegate.createFullBackup();

  @override
  LedgerBackupPreview inspectFullBackup(String source) =>
      _delegate.inspectFullBackup(source);

  @override
  Future<void> restoreFullBackup(
    String source, {
    required BackupRestoreMode mode,
  }) => _mutate(() => _delegate.restoreFullBackup(source, mode: mode));

  @override
  Future<void> resetLedgerData() => _mutate(_delegate.resetLedgerData);

  @override
  Future<void> resetToFactoryDefaults() =>
      _mutate(_delegate.resetToFactoryDefaults);
}
