import 'dart:io';

import 'package:intl/intl.dart';
import 'package:ledger_pro/domain/import_export/local_backup.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

typedef BackupRootProvider = Future<Directory> Function();

class LocalBackupStore {
  LocalBackupStore({BackupRootProvider? rootProvider})
    : _rootProvider = rootProvider ?? _defaultRoot;

  static const maximumAutomaticBackups = 5;

  final BackupRootProvider _rootProvider;
  bool _automaticBackupCreatedThisSession = false;

  Future<String> get location async => (await _root()).path;

  Future<List<LocalBackupNode>> listBackups() async {
    final nodes = <LocalBackupNode>[];
    for (final kind in LocalBackupKind.values) {
      final directory = await _directory(kind);
      await for (final entity in directory.list()) {
        if (entity is! File || p.extension(entity.path) != '.json') continue;
        final stat = await entity.stat();
        nodes.add(
          LocalBackupNode(
            path: entity.path,
            kind: kind,
            name: _displayName(entity.path, kind, stat.modified),
            createdAt: stat.modified,
            sizeBytes: stat.size,
          ),
        );
      }
    }
    nodes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return nodes;
  }

  Future<LocalBackupNode> createManualBackup(
    String content, {
    String? name,
  }) async {
    final now = DateTime.now();
    final suffix = _safeName(name);
    final filename = ['manual', _fileTimestamp(now), ?suffix].join('-');
    final file = File(
      p.join((await _directory(LocalBackupKind.manual)).path, '$filename.json'),
    );
    await file.writeAsString(content, flush: true);
    return _nodeFor(file, LocalBackupKind.manual);
  }

  Future<String?> beginAutomaticBackup(String content) async {
    if (_automaticBackupCreatedThisSession) return null;
    final now = DateTime.now();
    final file = File(
      p.join(
        (await _directory(LocalBackupKind.automatic)).path,
        'automatic-${_fileTimestamp(now)}.json',
      ),
    );
    await file.writeAsString(content, flush: true);
    _automaticBackupCreatedThisSession = true;
    return file.path;
  }

  Future<void> commitAutomaticBackup(String? path) async {
    if (path == null) return;
    await _pruneAutomaticBackups(keeping: path);
  }

  Future<void> rollBackAutomaticBackup(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
    _automaticBackupCreatedThisSession = false;
  }

  Future<String> readBackup(LocalBackupNode node) =>
      File(node.path).readAsString();

  Future<LocalBackupNode> renameBackup(
    LocalBackupNode node,
    String newName,
  ) async {
    if (node.kind != LocalBackupKind.manual) {
      throw const FileSystemException('自动备份不能重命名');
    }
    final safeName = _safeName(newName);
    if (safeName == null) throw const FormatException('备份名称不能为空');
    final target = File(
      p.join(
        p.dirname(node.path),
        'manual-${_fileTimestamp(node.createdAt)}-$safeName.json',
      ),
    );
    if (await target.exists() && target.path != node.path) {
      throw const FileSystemException('同名备份已经存在');
    }
    final renamed = await File(node.path).rename(target.path);
    return _nodeFor(renamed, node.kind);
  }

  Future<void> deleteBackup(LocalBackupNode node) async {
    final file = File(node.path);
    if (await file.exists()) await file.delete();
  }

  Future<void> clearAllBackups() async {
    final root = await _root();
    if (await root.exists()) await root.delete(recursive: true);
    _automaticBackupCreatedThisSession = false;
  }

  Future<void> _pruneAutomaticBackups({required String keeping}) async {
    final directory = await _directory(LocalBackupKind.automatic);
    final files = <File>[];
    await for (final entity in directory.list()) {
      if (entity is File && p.extension(entity.path) == '.json') {
        files.add(entity);
      }
    }
    if (files.length <= maximumAutomaticBackups) return;
    final dated = <({File file, DateTime modified})>[];
    for (final file in files) {
      dated.add((file: file, modified: (await file.stat()).modified));
    }
    dated.sort((a, b) => b.modified.compareTo(a.modified));
    for (final item in dated.skip(maximumAutomaticBackups)) {
      if (item.file.path != keeping && await item.file.exists()) {
        await item.file.delete();
      }
    }
  }

  Future<LocalBackupNode> _nodeFor(File file, LocalBackupKind kind) async {
    final stat = await file.stat();
    return LocalBackupNode(
      path: file.path,
      kind: kind,
      name: _displayName(file.path, kind, stat.modified),
      createdAt: stat.modified,
      sizeBytes: stat.size,
    );
  }

  Future<Directory> _root() async {
    final directory = await _rootProvider();
    await directory.create(recursive: true);
    return directory;
  }

  Future<Directory> _directory(LocalBackupKind kind) async {
    final directory = Directory(p.join((await _root()).path, kind.name));
    await directory.create(recursive: true);
    return directory;
  }

  static Future<Directory> _defaultRoot() async {
    final documents = await getApplicationDocumentsDirectory();
    return Directory(p.join(documents.path, 'summa_backups'));
  }

  static String _fileTimestamp(DateTime value) =>
      DateFormat('yyyyMMdd-HHmmss-SSS').format(value);

  static String? _safeName(String? value) {
    if (value == null) return null;
    final normalized = value.trim().replaceAll(
      RegExp(r'[^\w\u4e00-\u9fff-]+'),
      '_',
    );
    if (normalized.isEmpty) return null;
    return normalized.substring(0, normalized.length.clamp(0, 40));
  }

  static String _displayName(
    String path,
    LocalBackupKind kind,
    DateTime modified,
  ) {
    final base = p.basenameWithoutExtension(path);
    if (kind == LocalBackupKind.manual) {
      final match = RegExp(r'^manual-\d{8}-\d{6}-\d{3}-(.+)$').firstMatch(base);
      if (match != null) return match.group(1)!.replaceAll('_', ' ');
    }
    final prefix = kind == LocalBackupKind.automatic ? '自动备份' : '手动备份';
    return '$prefix ${DateFormat('MM-dd HH:mm').format(modified)}';
  }
}
