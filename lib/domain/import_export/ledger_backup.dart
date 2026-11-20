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
  });

  final DateTime createdAt;
  final int accountCount;
  final int categoryCount;
  final int entryCount;
  final int deletedEntryCount;
  final int checkpointCount;
  final int importBatchCount;
}

class LedgerBackupException implements Exception {
  const LedgerBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}
