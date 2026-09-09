import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger_pro/data/backup/local_backup_store.dart';
import 'package:ledger_pro/data/database/app_database.dart';
import 'package:ledger_pro/data/repositories/auto_backup_expense_repository.dart';
import 'package:ledger_pro/data/repositories/drift_expense_repository.dart';
import 'package:ledger_pro/domain/accounts/ledger_account.dart';
import 'package:ledger_pro/domain/categories/ledger_category.dart';
import 'package:ledger_pro/domain/transactions/expense_record.dart';
import 'package:ledger_pro/domain/transactions/expense_repository.dart';

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

final expenseCategoriesProvider = StreamProvider<List<LedgerCategory>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchExpenseCategories();
});

final incomeCategoriesProvider = StreamProvider<List<LedgerCategory>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchIncomeCategories();
});
