enum BackupRestoreMode { replace, merge }

class LedgerBackupPreview {
  const LedgerBackupPreview({
    required this.createdAt,
    required this.accountCount,
    required this.categoryCount,
    required this.entryCount,
    required this.deletedEntryCount,
    this.checkpointCount = 0,
    this.importBatchCount = 0,
    this.spendingPlanCount = 0,
    this.recurringPlanCount = 0,
  });

  final DateTime createdAt;
  final int accountCount;
  final int categoryCount;
  final int entryCount;
  final int deletedEntryCount;
  final int checkpointCount;
  final int importBatchCount;
  final int spendingPlanCount;
  final int recurringPlanCount;
}

class LedgerBackupException implements Exception {
  const LedgerBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}
