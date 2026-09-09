import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ledger_pro/app/providers.dart';
import 'package:ledger_pro/domain/import_export/ledger_backup.dart';
import 'package:ledger_pro/domain/import_export/local_backup.dart';
import 'package:share_plus/share_plus.dart';

class DataManagementScreen extends ConsumerStatefulWidget {
  const DataManagementScreen({super.key});

  @override
  ConsumerState<DataManagementScreen> createState() =>
      _DataManagementScreenState();
}

class _DataManagementScreenState extends ConsumerState<DataManagementScreen> {
  var _busy = false;
  var _backups = <LocalBackupNode>[];
  String? _location;

  @override
  void initState() {
    super.initState();
    _reloadBackups();
  }

  @override
  Widget build(BuildContext context) {
    final automatic = _backups
        .where((item) => item.kind == LocalBackupKind.automatic)
        .toList();
    final manual = _backups
        .where((item) => item.kind == LocalBackupKind.manual)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('数据与备份')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card.filled(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '完整备份由你掌控',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '本地节点保存在 Summa 的应用专属文档目录；新版 Android 的普通文件管理器可能不会直接显示该目录，请在本页管理或导出。',
                  ),
                  if (_location != null) ...[
                    const SizedBox(height: 10),
                    SelectableText(
                      _location!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 20),
          const _SectionTitle(
            title: '自动备份',
            subtitle: '每次启动后的第一次成功修改前保存，滚动保留最近 5 个节点。',
          ),
          const SizedBox(height: 8),
          _BackupCard(
            emptyText: '本次启动尚未发生有效修改',
            nodes: automatic,
            enabled: !_busy,
            onAction: _handleNodeAction,
          ),
          const SizedBox(height: 20),
          const _SectionTitle(
            title: '手动备份',
            subtitle: '本地节点留在应用中；导出分享可保存到文件管理器、云盘或其他位置。',
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.save_outlined),
                  title: const Text('备份到软件本地'),
                  subtitle: const Text('创建一个不受 5 个自动节点限制的手动节点'),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: !_busy,
                  onTap: _createManualBackup,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.ios_share_outlined),
                  title: const Text('导出或分享备份'),
                  subtitle: const Text('生成 Summa 完整 JSON 备份并交给系统保存'),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: !_busy,
                  onTap: _exportBackup,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_open_outlined),
                  title: const Text('从外部备份文件恢复'),
                  subtitle: const Text('选择 JSON 文件后覆盖回档或合并'),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: !_busy,
                  onTap: _pickAndRestore,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _BackupCard(
            emptyText: '还没有手动本地备份',
            nodes: manual,
            enabled: !_busy,
            onAction: _handleNodeAction,
          ),
          const SizedBox(height: 24),
          const _SectionTitle(
            title: '重置',
            subtitle: '重置账本会保留本地备份，恢复出厂会同时删除它们。',
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cleaning_services_outlined),
                  title: const Text('重置账单与账户'),
                  subtitle: const Text('清空账单，账户恢复默认且余额归零；保留分类和备份'),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: !_busy,
                  onTap: _resetLedgerData,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    '恢复出厂设置',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  subtitle: const Text('清空账单、账户、分类以及所有本地备份'),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: !_busy,
                  onTap: _factoryReset,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _reloadBackups() async {
    final store = ref.read(localBackupStoreProvider);
    try {
      final backups = await store.listBackups();
      final location = await store.location;
      if (!mounted) return;
      setState(() {
        _backups = backups;
        _location = location;
      });
    } catch (_) {
      if (mounted) _message('无法读取本地备份目录');
    }
  }

  Future<void> _createManualBackup() async {
    final name = await _askForName(title: '手动备份名称', initial: '我的备份');
    if (name == null || !mounted) return;
    await _runBusy(() async {
      final content = await ref
          .read(expenseRepositoryProvider)
          .createFullBackup();
      await ref
          .read(localBackupStoreProvider)
          .createManualBackup(content, name: name);
      await _reloadBackups();
      if (mounted) _message('手动备份已保存到软件本地');
    }, failure: '创建本地备份失败');
  }

  Future<void> _exportBackup() async {
    await _runBusy(() async {
      final content = await ref
          .read(expenseRepositoryProvider)
          .createFullBackup();
      if (!mounted) return;
      final now = DateTime.now();
      final name =
          'summa-full-${DateFormat('yyyyMMdd-HHmmss').format(now)}.json';
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(utf8.encode(content), mimeType: 'application/json'),
          ],
          fileNameOverrides: [name],
          subject: 'Summa 完整备份',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    }, failure: '备份导出失败，请重试');
  }

  Future<void> _pickAndRestore() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (file == null || !mounted) return;
    try {
      await _restoreSource(
        utf8.decode(await file.readAsBytes()),
        sourceName: file.name,
      );
    } catch (_) {
      if (mounted) _message('无法读取所选备份文件');
    }
  }

  Future<void> _handleNodeAction(
    LocalBackupNode node,
    _BackupNodeAction action,
  ) async {
    switch (action) {
      case _BackupNodeAction.replace:
        final source = await _readNode(node);
        if (source == null) return;
        await _restoreSource(source, sourceName: node.name, replaceOnly: true);
      case _BackupNodeAction.merge:
        final source = await _readNode(node);
        if (source == null) return;
        await _restoreSource(source, sourceName: node.name, mergeOnly: true);
      case _BackupNodeAction.rename:
        final name = await _askForName(title: '重命名备份', initial: node.name);
        if (name == null || !mounted) return;
        await _runBusy(() async {
          await ref.read(localBackupStoreProvider).renameBackup(node, name);
          await _reloadBackups();
        }, failure: '重命名失败，请检查是否存在同名备份');
      case _BackupNodeAction.delete:
        final confirmed = await _confirm(
          title: '删除备份节点？',
          message: '“${node.name}”将被永久删除，无法撤销。',
          confirmLabel: '删除',
        );
        if (!confirmed || !mounted) return;
        await _runBusy(() async {
          await ref.read(localBackupStoreProvider).deleteBackup(node);
          await _reloadBackups();
        }, failure: '删除备份失败');
    }
  }

  Future<String?> _readNode(LocalBackupNode node) async {
    try {
      return await ref.read(localBackupStoreProvider).readBackup(node);
    } catch (_) {
      if (mounted) _message('备份节点已不存在或无法读取');
      await _reloadBackups();
      return null;
    }
  }

  Future<void> _restoreSource(
    String source, {
    required String sourceName,
    bool replaceOnly = false,
    bool mergeOnly = false,
  }) async {
    final repository = ref.read(expenseRepositoryProvider);
    try {
      final preview = repository.inspectFullBackup(source);
      if (!mounted) return;
      final mode = replaceOnly
          ? await _confirmRestore(
              preview,
              sourceName,
              BackupRestoreMode.replace,
            )
          : mergeOnly
          ? await _confirmRestore(preview, sourceName, BackupRestoreMode.merge)
          : await _chooseRestoreMode(preview, sourceName);
      if (mode == null || !mounted) return;
      await _runBusy(() async {
        await repository.restoreFullBackup(source, mode: mode);
        await _reloadBackups();
        if (mounted) {
          _message(mode == BackupRestoreMode.replace ? '已回档到所选备份' : '备份已合并');
        }
      }, failure: '恢复失败，数据库没有被部分修改');
    } on LedgerBackupException catch (error) {
      if (mounted) _message(error.message);
    }
  }

  Future<BackupRestoreMode?> _chooseRestoreMode(
    LedgerBackupPreview preview,
    String sourceName,
  ) => showDialog<BackupRestoreMode>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('确认恢复内容'),
      content: _BackupPreview(preview: preview, sourceName: sourceName),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(context, BackupRestoreMode.merge),
          child: const Text('合并'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, BackupRestoreMode.replace),
          child: const Text('覆盖回档'),
        ),
      ],
    ),
  );

  Future<BackupRestoreMode?> _confirmRestore(
    LedgerBackupPreview preview,
    String sourceName,
    BackupRestoreMode mode,
  ) => showDialog<BackupRestoreMode>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(mode == BackupRestoreMode.replace ? '回档到此节点？' : '合并此节点？'),
      content: _BackupPreview(preview: preview, sourceName: sourceName),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, mode),
          child: Text(mode == BackupRestoreMode.replace ? '确认回档' : '确认合并'),
        ),
      ],
    ),
  );

  Future<void> _resetLedgerData() async {
    final confirmed = await _confirm(
      title: '重置账单与账户？',
      message: '全部账单将被永久清除，自定义账户将删除，默认账户余额归零。分类和所有备份会保留。',
      confirmLabel: '确认重置',
    );
    if (!confirmed || !mounted) return;
    await _runBusy(() async {
      await ref.read(expenseRepositoryProvider).resetLedgerData();
      await _reloadBackups();
      if (mounted) _message('账单与账户已重置，备份均已保留');
    }, failure: '重置失败，数据没有被部分修改');
  }

  Future<void> _factoryReset() async {
    final confirmed = await _confirm(
      title: '恢复出厂设置？',
      message: '账单、账户、分类和软件内全部备份都将永久清除。导出到应用外部的文件不受影响。',
      confirmLabel: '全部清除',
    );
    if (!confirmed || !mounted) return;
    await _runBusy(() async {
      await ref.read(expenseRepositoryProvider).resetToFactoryDefaults();
      await ref.read(localBackupStoreProvider).clearAllBackups();
      await _reloadBackups();
      if (mounted) _message('Summa 已恢复出厂设置');
    }, failure: '恢复出厂设置失败');
  }

  Future<String?> _askForName({
    required String title,
    required String initial,
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(labelText: '名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _runBusy(
    Future<void> Function() action, {
    required String failure,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) _message(failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _BackupNodeAction { replace, merge, rename, delete }

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _BackupCard extends StatelessWidget {
  const _BackupCard({
    required this.emptyText,
    required this.nodes,
    required this.enabled,
    required this.onAction,
  });

  final String emptyText;
  final List<LocalBackupNode> nodes;
  final bool enabled;
  final Future<void> Function(LocalBackupNode, _BackupNodeAction) onAction;

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.history_toggle_off),
              const SizedBox(width: 12),
              Expanded(child: Text(emptyText)),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          for (var index = 0; index < nodes.length; index++) ...[
            _BackupTile(
              node: nodes[index],
              enabled: enabled,
              onAction: onAction,
            ),
            if (index != nodes.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _BackupTile extends StatelessWidget {
  const _BackupTile({
    required this.node,
    required this.enabled,
    required this.onAction,
  });

  final LocalBackupNode node;
  final bool enabled;
  final Future<void> Function(LocalBackupNode, _BackupNodeAction) onAction;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: enabled ? () => onAction(node, _BackupNodeAction.replace) : null,
    leading: Icon(
      node.kind == LocalBackupKind.automatic
          ? Icons.history_rounded
          : Icons.save_outlined,
    ),
    title: Text(node.name),
    subtitle: Text(
      '${DateFormat('yyyy-MM-dd HH:mm:ss').format(node.createdAt)} · ${_formatSize(node.sizeBytes)} · 点击回档',
    ),
    trailing: PopupMenuButton<_BackupNodeAction>(
      enabled: enabled,
      onSelected: (action) => onAction(node, action),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _BackupNodeAction.replace,
          child: Text('覆盖回档'),
        ),
        const PopupMenuItem(
          value: _BackupNodeAction.merge,
          child: Text('合并到当前账本'),
        ),
        if (node.kind == LocalBackupKind.manual)
          const PopupMenuItem(
            value: _BackupNodeAction.rename,
            child: Text('重命名'),
          ),
        const PopupMenuItem(value: _BackupNodeAction.delete, child: Text('删除')),
      ],
    ),
  );
}

class _BackupPreview extends StatelessWidget {
  const _BackupPreview({required this.preview, required this.sourceName});

  final LedgerBackupPreview preview;
  final String sourceName;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(sourceName, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 10),
      Text('备份时间：${DateFormat('yyyy-MM-dd HH:mm').format(preview.createdAt)}'),
      Text('账户：${preview.accountCount}'),
      Text('分类：${preview.categoryCount}'),
      Text('账单：${preview.entryCount}（含 ${preview.deletedEntryCount} 条已删除记录）'),
      const SizedBox(height: 12),
      const Text('执行成功前，Summa 会按本次启动的自动备份规则保护当前状态。'),
    ],
  );
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}
