import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/domain/import_export/csv_import.dart';
import 'package:summa/l10n/l10n.dart';

import 'csv_import_labels.dart';

class CsvImportHistoryScreen extends ConsumerWidget {
  const CsvImportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(labels.csvHistory)),
      body: ref
          .watch(csvBatchesProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(csvBatchesProvider),
                child: Text(labels.retry),
              ),
            ),
            data: (batches) => batches.isEmpty
                ? Center(child: Text(labels.csvNoHistory))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: batches.length,
                    itemBuilder: (_, index) {
                      final batch = batches[index];
                      return Card(
                        child: ListTile(
                          title: Text(batch.name),
                          subtitle: Text(
                            [
                              _date(context, batch.createdAt),
                              labels.csvBatchCounts(batch.added, batch.matched),
                              if (batch.undoneAt != null) labels.csvUndone,
                            ].join(' · '),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push<void>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _BatchDetails(id: batch.id),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
    );
  }
}

class _BatchDetails extends ConsumerStatefulWidget {
  const _BatchDetails({required this.id});
  final String id;

  @override
  ConsumerState<_BatchDetails> createState() => _BatchDetailsState();
}

class _BatchDetailsState extends ConsumerState<_BatchDetails> {
  bool _busy = false;
  String? _error;

  Future<void> _undo() async {
    final labels = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(labels.csvUndo),
        content: Text(labels.csvConfirmUndo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(labels.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(labels.csvUndo),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(expenseRepositoryProvider).undoCsvImport(widget.id);
    } catch (error) {
      if (mounted) setState(() => _error = csvErrorText(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final batches = ref.watch(csvBatchesProvider);
    final items = ref.watch(csvBatchItemsProvider(widget.id));
    return Scaffold(
      appBar: AppBar(title: Text(labels.csvBatchDetails)),
      body: batches.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(csvBatchesProvider),
            child: Text(labels.retry),
          ),
        ),
        data: (all) {
          final batch = all.where((batch) => batch.id == widget.id).firstOrNull;
          if (batch == null) {
            return Center(child: Text(labels.csvBatchUnavailable));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batch.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(_date(context, batch.createdAt)),
                    Text(labels.csvBatchCounts(batch.added, batch.matched)),
                    if (batch.undoneAt case final time?)
                      Text('${labels.csvUndone} · ${_date(context, time)}'),
                  ],
                ),
              ),
              Expanded(
                child: items.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Center(
                    child: TextButton(
                      onPressed: () =>
                          ref.invalidate(csvBatchItemsProvider(widget.id)),
                      child: Text(labels.retry),
                    ),
                  ),
                  data: (rows) => ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: rows.length,
                    itemBuilder: (_, index) => _BatchRow(rows[index]),
                  ),
                ),
              ),
              if (_error case final error?)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (batch.undoneAt == null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: OutlinedButton(
                      onPressed: _busy ? null : _undo,
                      child: Text(_busy ? labels.saving : labels.csvUndo),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BatchRow extends StatelessWidget {
  const _BatchRow(this.item);
  final CsvBatchItem item;

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final raw = item.raw;
    return Card(
      child: ListTile(
        title: Text(
          '${labels.csvLine(item.line)} · ${item.created ? labels.csvCreatedRow : labels.csvLinkedRow}',
        ),
        subtitle: Text(
          [
            for (final key in ['amount', 'currency_code', 'account', 'note'])
              if ((raw[key] ?? '').isNotEmpty) raw[key]!,
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => showDialog<void>(
          context: context,
          builder: (dialog) => AlertDialog(
            title: Text(labels.csvOriginalRow),
            content: SingleChildScrollView(
              child: SelectableText(
                [
                  for (final field in raw.entries)
                    '${field.key}\n${field.value}',
                  '${labels.csvLedgerId}\n${item.entryId}',
                ].join('\n\n'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: Text(labels.close),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _date(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
        .add_Hm()
        .format(date.toLocal());
