enum LocalBackupKind { automatic, manual }

class LocalBackupNode {
  const LocalBackupNode({
    required this.path,
    required this.kind,
    required this.name,
    required this.createdAt,
    required this.sizeBytes,
  });

  final String path;
  final LocalBackupKind kind;
  final String name;
  final DateTime createdAt;
  final int sizeBytes;
}
