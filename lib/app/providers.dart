import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:summa/data/backup/local_backup_store.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/data/repositories/auto_backup_expense_repository.dart';
import 'package:summa/data/repositories/drift_expense_repository.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/analytics/cash_forecast.dart';
import 'package:summa/domain/analytics/ledger_history.dart';
import 'package:summa/domain/categories/ledger_category.dart';
import 'package:summa/domain/import_export/csv_import.dart';
import 'package:summa/domain/import_export/import_category_rule.dart';
import 'package:summa/domain/planning/debt_contract.dart';
import 'package:summa/domain/planning/recurring_plan.dart';
import 'package:summa/domain/planning/savings_goal.dart';
import 'package:summa/domain/planning/spending_plan.dart';
import 'package:summa/domain/reconciliation/balance_checkpoint.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/expense_repository.dart';
import 'package:summa/domain/valuation/net_worth_valuation.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final localBackupStoreProvider = Provider<LocalBackupStore>((ref) {
  return LocalBackupStore();
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return AutoBackupExpenseRepository(
    DriftExpenseRepository(ref.watch(databaseProvider)),
    ref.watch(localBackupStoreProvider),
  );
});

final transactionsProvider = StreamProvider<List<LedgerRecord>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchTransactions();
});

final accountsProvider = StreamProvider<List<LedgerAccount>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchAccounts();
});

final accountBalancesProvider = StreamProvider<List<AccountBalance>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchAccountBalances();
});

final ledgerHistoryInputsProvider =
    StreamProvider.autoDispose<LedgerHistoryInputs>(
      (ref) => ref.watch(expenseRepositoryProvider).watchLedgerHistoryInputs(),
    );

final cashForecastInputsProvider =
    StreamProvider.autoDispose<CashForecastInputs>(
      (ref) => ref.watch(expenseRepositoryProvider).watchCashForecastInputs(),
    );

final expenseCategoriesProvider = StreamProvider<List<LedgerCategory>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchExpenseCategories();
});

final incomeCategoriesProvider = StreamProvider<List<LedgerCategory>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchIncomeCategories();
});

final valuationSettingsProvider = StreamProvider<ValuationSettings>((ref) {
  return ref.watch(expenseRepositoryProvider).watchValuationSettings();
});

final balanceCheckpointsProvider = StreamProvider.autoDispose
    .family<List<BalanceCheckpoint>, String>((ref, id) {
      return ref.watch(expenseRepositoryProvider).watchBalanceCheckpoints(id);
    });

final csvBatchesProvider = StreamProvider.autoDispose<List<CsvBatchSummary>>((
  ref,
) {
  return ref.watch(expenseRepositoryProvider).watchCsvBatches();
});

final csvBatchItemsProvider = FutureProvider.autoDispose
    .family<List<CsvBatchItem>, String>((ref, id) {
      return ref.watch(expenseRepositoryProvider).readCsvBatchItems(id);
    });

final importCategoryRulesProvider =
    StreamProvider.autoDispose<List<ImportCategoryRule>>((ref) {
      return ref.watch(expenseRepositoryProvider).watchImportRules();
    });

final spendingPlansProvider = StreamProvider.autoDispose<List<SpendingPlan>>(
  (ref) => ref.watch(expenseRepositoryProvider).watchSpendingPlans(),
);

final recurringPlansProvider = StreamProvider.autoDispose<List<RecurringPlan>>(
  (ref) => ref.watch(expenseRepositoryProvider).watchRecurringPlans(),
);

final debtContractsProvider = StreamProvider.autoDispose<List<DebtContract>>(
  (ref) => ref.watch(expenseRepositoryProvider).watchDebtContracts(),
);

final savingsAllocationsProvider =
    StreamProvider.autoDispose<List<SavingsAccountAllocation>>(
      (ref) => ref.watch(expenseRepositoryProvider).watchSavingsAllocations(),
    );
