import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ledger_pro/app/providers.dart';
import 'package:ledger_pro/domain/import_export/ledger_backup.dart';
import 'package:ledger_pro/domain/import_export/local_backup.dart';
import 'package:ledger_pro/l10n/l10n.dart';
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
      appBar: AppBar(title: Text(context.l10n.dataAndBackup)),
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
                    context.l10n.backupUnderYourControl,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(context.l10n.backupLocationDescription),
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
          _SectionTitle(
            title: context.l10n.automaticBackups,
            subtitle: context.l10n.automaticBackupsSubtitle,
          ),
          const SizedBox(height: 8),
          _BackupCard(
            emptyText: context.l10n.noAutomaticBackupYet,
            nodes: automatic,
            enabled: !_busy,
            onAction: _handleNodeAction,
          ),
          const SizedBox(height: 20),
          _SectionTitle(
            title: context.l10n.manualBackups,
            subtitle: context.l10n.manualBackupsSubtitle,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.save_outlined),
                  title: Text(context.l10n.backupInsideApp),
                  subtitle: Text(context.l10n.backupInsideAppSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: !_busy,
                  onTap: _createManualBackup,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.ios_share_outlined),
                  title: Text(context.l10n.exportOrShareBackup),
                  subtitle: Text(context.l10n.exportOrShareBackupSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: !_busy,
                  onTap: _exportBackup,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_open_outlined),
                  title: Text(context.l10n.restoreExternalBackup),
                  subtitle: Text(context.l10n.restoreExternalBackupSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: !_busy,
                  onTap: _pickAndRestore,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _BackupCard(
            emptyText: context.l10n.noManualBackups,
            nodes: manual,
            enabled: !_busy,
            onAction: _handleNodeAction,
          ),
          const SizedBox(height: 24),
          _SectionTitle(
            title: context.l10n.reset,
            subtitle: context.l10n.resetSubtitle,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cleaning_services_outlined),
                  title: Text(context.l10n.resetTransactionsAccounts),
                  subtitle: Text(
                    context.l10n.resetTransactionsAccountsSubtitle,
                  ),
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
                    context.l10n.factoryReset,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  subtitle: Text(context.l10n.factoryResetSubtitle),
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
      if (mounted) _message(context.l10n.cannotReadBackupDirectory);
    }
  }

  Future<void> _createManualBackup() async {
    final name = await _askForName(
      title: context.l10n.manualBackupName,
      initial: context.l10n.myBackup,
    );
    if (name == null || !mounted) return;
    await _runBusy(() async {
      final content = await ref
          .read(expenseRepositoryProvider)
          .createFullBackup();
      await ref
          .read(localBackupStoreProvider)
          .createManualBackup(content, name: name);
      await _reloadBackups();
      if (mounted) _message(context.l10n.manualBackupSaved);
    }, failure: context.l10n.createLocalBackupFailed);
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
          subject: context.l10n.completeBackupSubject,
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    }, failure: context.l10n.backupExportFailed);
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
      if (mounted) _message(context.l10n.cannotReadSelectedBackup);
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
        final name = await _askForName(
          title: context.l10n.renameBackup,
          initial: node.name,
        );
        if (name == null || !mounted) return;
        await _runBusy(() async {
          await ref.read(localBackupStoreProvider).renameBackup(node, name);
          await _reloadBackups();
        }, failure: context.l10n.renameBackupFailed);
      case _BackupNodeAction.delete:
        final confirmed = await _confirm(
          title: context.l10n.deleteBackupTitle,
          message: context.l10n.deleteBackupMessage(node.name),
          confirmLabel: context.l10n.delete,
        );
        if (!confirmed || !mounted) return;
        await _runBusy(() async {
          await ref.read(localBackupStoreProvider).deleteBackup(node);
          await _reloadBackups();
        }, failure: context.l10n.deleteBackupFailed);
    }
  }

  Future<String?> _readNode(LocalBackupNode node) async {
    try {
      return await ref.read(localBackupStoreProvider).readBackup(node);
    } catch (_) {
      if (mounted) _message(context.l10n.backupNoLongerAvailable);
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
          _message(
            mode == BackupRestoreMode.replace
                ? context.l10n.restoredSelectedBackup
                : context.l10n.backupMerged,
          );
        }
      }, failure: context.l10n.restoreDatabaseSafeFailure);
    } on LedgerBackupException catch (error) {
      if (mounted) {
        _message(_localizedBackupError(context, error.message));
      }
    }
  }

  Future<BackupRestoreMode?> _chooseRestoreMode(
    LedgerBackupPreview preview,
    String sourceName,
  ) => showDialog<BackupRestoreMode>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.l10n.confirmRestoreContents),
      content: _BackupPreview(preview: preview, sourceName: sourceName),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(context, BackupRestoreMode.merge),
          child: Text(context.l10n.merge),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, BackupRestoreMode.replace),
          child: Text(context.l10n.replaceAndRestore),
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
      title: Text(
        mode == BackupRestoreMode.replace
            ? context.l10n.restoreThisSnapshotTitle
            : context.l10n.mergeThisSnapshotTitle,
      ),
      content: _BackupPreview(preview: preview, sourceName: sourceName),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, mode),
          child: Text(
            mode == BackupRestoreMode.replace
                ? context.l10n.confirmRestore
                : context.l10n.confirmMerge,
          ),
        ),
      ],
    ),
  );

  Future<void> _resetLedgerData() async {
    final confirmed = await _confirm(
      title: context.l10n.resetTransactionsAccountsTitle,
      message: context.l10n.resetTransactionsAccountsMessage,
      confirmLabel: context.l10n.confirmReset,
    );
    if (!confirmed || !mounted) return;
    await _runBusy(() async {
      await ref.read(expenseRepositoryProvider).resetLedgerData();
      await _reloadBackups();
      if (mounted) _message(context.l10n.transactionsAccountsReset);
    }, failure: context.l10n.resetSafeFailure);
  }

  Future<void> _factoryReset() async {
    final confirmed = await _confirm(
      title: context.l10n.factoryResetTitle,
      message: context.l10n.factoryResetMessage,
      confirmLabel: context.l10n.clearEverything,
    );
    if (!confirmed || !mounted) return;
    await _runBusy(() async {
      await ref.read(expenseRepositoryProvider).resetToFactoryDefaults();
      await ref.read(localBackupStoreProvider).clearAllBackups();
      await _reloadBackups();
      if (mounted) _message(context.l10n.factoryResetComplete);
    }, failure: context.l10n.factoryResetFailed);
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
          decoration: InputDecoration(labelText: context.l10n.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: Text(context.l10n.save),
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
              child: Text(context.l10n.cancel),
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
    title: Text(
      node.kind == LocalBackupKind.automatic
          ? context.l10n.automaticBackupName
          : node.name,
    ),
    subtitle: Text(
      '${DateFormat.yMd(Localizations.localeOf(context).toLanguageTag()).add_Hms().format(node.createdAt)} · '
      '${_formatSize(node.sizeBytes)} · ${context.l10n.tapToRestore}',
    ),
    trailing: PopupMenuButton<_BackupNodeAction>(
      enabled: enabled,
      onSelected: (action) => onAction(node, action),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _BackupNodeAction.replace,
          child: Text(context.l10n.replaceAndRestore),
        ),
        PopupMenuItem(
          value: _BackupNodeAction.merge,
          child: Text(context.l10n.mergeIntoLedger),
        ),
        if (node.kind == LocalBackupKind.manual)
          PopupMenuItem(
            value: _BackupNodeAction.rename,
            child: Text(context.l10n.rename),
          ),
        PopupMenuItem(
          value: _BackupNodeAction.delete,
          child: Text(context.l10n.delete),
        ),
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
      Text(
        context.l10n.backupTime(
          DateFormat.yMd(Localizations.localeOf(context).toLanguageTag())
              .add_Hm()
              .format(preview.createdAt),
        ),
      ),
      Text(context.l10n.backupAccountCount(preview.accountCount)),
      Text(context.l10n.backupCategoryCount(preview.categoryCount)),
      Text(
        context.l10n.backupTransactionCount(
          preview.entryCount,
          preview.deletedEntryCount,
        ),
      ),
      const SizedBox(height: 12),
      Text(context.l10n.restoreSafetyHint),
    ],
  );
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}

String _localizedBackupError(BuildContext context, String message) {
  if (Localizations.localeOf(context).languageCode == 'zh') return message;
  if (message.startsWith('备份 JSON 格式错误：')) {
    return context.l10n.backupInvalidJson(
      message.substring('备份 JSON 格式错误：'.length),
    );
  }
  if (message == '这不是受支持的 Summa 完整备份') {
    return context.l10n.backupUnsupported;
  }
  if (message == '备份时间无效') return context.l10n.backupInvalidTime;
  final patterns = <(RegExp, String Function(RegExpMatch))>[
    (
      RegExp(r'^备份缺少 (.+) 列表$'),
      (match) => context.l10n.backupMissingList(match.group(1)!),
    ),
    (
      RegExp(r'^(.+) 中包含无效项目$'),
      (match) => context.l10n.backupInvalidItem(match.group(1)!),
    ),
    (
      RegExp(r'^字段 (.+) 必须是字符串$'),
      (match) => context.l10n.backupFieldMustString(match.group(1)!),
    ),
    (
      RegExp(r'^字段 (.+) 必须是字符串或 null$'),
      (match) => context.l10n.backupFieldMustNullableString(match.group(1)!),
    ),
    (
      RegExp(r'^字段 (.+) 必须是整数$'),
      (match) => context.l10n.backupFieldMustInteger(match.group(1)!),
    ),
    (
      RegExp(r'^字段 (.+) 必须是布尔值$'),
      (match) => context.l10n.backupFieldMustBoolean(match.group(1)!),
    ),
    (
      RegExp(r'^字段 (.+) 不是有效时间$'),
      (match) => context.l10n.backupFieldInvalidTime(match.group(1)!),
    ),
    (
      RegExp(r'^字段 (.+) 的值不受支持：(.*)$'),
      (match) => context.l10n.backupFieldUnsupportedValue(
        match.group(1)!,
        match.group(2)!,
      ),
    ),
  ];
  for (final (pattern, translate) in patterns) {
    final match = pattern.firstMatch(message);
    if (match != null) return translate(match);
  }
  return context.l10n.restoreDatabaseSafeFailure;
}
