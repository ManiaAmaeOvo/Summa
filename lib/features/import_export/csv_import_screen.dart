import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/categories/ledger_category.dart';
import 'package:summa/domain/import_export/csv_import.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/l10n/default_ledger_labels.dart';
import 'package:summa/l10n/l10n.dart';

import 'csv_import_history_screen.dart';
import 'csv_import_labels.dart';
import 'import_category_rules_screen.dart';
import 'import_rule_labels.dart';
import 'statement_input.dart';

class CsvImportScreen extends ConsumerStatefulWidget {
  const CsvImportScreen({super.key});

  @override
  ConsumerState<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends ConsumerState<CsvImportScreen> {
  CsvImportFile? _file;
  List<CsvReviewRow> _rows = const [];
  final _mappings = <int, CsvMapping>{};
  final _selected = <int, CsvSelection>{};
  String? _error;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(labels.csvImport),
        actions: [
          IconButton(
            icon: const Icon(Icons.rule_outlined),
            tooltip: labels.importCategoryRules,
            onPressed: _busy
                ? null
                : () async {
                    await Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ImportCategoryRulesScreen(sample: _file),
                      ),
                    );
                    if (mounted && _file != null) await _refresh();
                  },
          ),
          IconButton(
            tooltip: labels.csvHistory,
            onPressed: _busy
                ? null
                : () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CsvImportHistoryScreen(),
                    ),
                  ),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: SafeArea(child: _file == null ? _input() : _preview()),
    );
  }

  Widget _input() {
    final labels = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(labels.csvInstructions),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : _pickFile,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(labels.csvChooseFile),
        ),
        OutlinedButton(
          onPressed: _busy ? null : _paste,
          child: Text(labels.csvPaste),
        ),
        TextButton.icon(
          onPressed: _busy
              ? null
              : () => _copy(csvImportTemplate, labels.importTemplateCopied),
          icon: const Icon(Icons.copy),
          label: Text(labels.copyTemplate),
        ),
        TextButton.icon(
          onPressed: _busy
              ? null
              : () => _copy(
                  labels.csvScreenshotPrompt,
                  labels.csvScreenshotPromptCopied,
                ),
          icon: const Icon(Icons.document_scanner_outlined),
          label: Text(labels.csvCopyScreenshotPrompt),
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_error case final error?) _ErrorText(error),
      ],
    );
  }

  Future<void> _copy(String value, String confirmation) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(confirmation)));
    }
  }

  Widget _preview() {
    final labels = context.l10n;
    final locale = Localizations.localeOf(context);
    final accountNames = {
      for (final account
          in ref.watch(accountsProvider).asData?.value ??
              const <LedgerAccount>[])
        account.id: DefaultLedgerLabels.accountName(
          locale,
          account.id,
          account.name,
        ),
    };
    final categoryNames = {
      for (final category in [
        ...?ref.watch(expenseCategoriesProvider).asData?.value,
        ...?ref.watch(incomeCategoriesProvider).asData?.value,
      ])
        category.id: DefaultLedgerLabels.category(context, category),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_file!.name, style: Theme.of(context).textTheme.titleMedium),
              Text(labels.csvReviewSummary(_rows.length, _selected.length)),
            ],
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: _rows.length,
            itemBuilder: (_, index) =>
                _rowTile(_rows[index], accountNames, categoryNames),
          ),
        ),
        if (_error case final error?) _ErrorText(error),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Row(
            children: [
              IconButton(
                tooltip: labels.csvChangeFile,
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _file = null;
                        _rows = const [];
                        _mappings.clear();
                        _selected.clear();
                        _error = null;
                      }),
                icon: const Icon(Icons.close),
              ),
              IconButton(
                tooltip: labels.csvRefresh,
                onPressed: _busy ? null : _refresh,
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _busy || _selected.isEmpty ? null : _commit,
                  child: Text(labels.csvCommit(_selected.length)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rowTile(
    CsvReviewRow item,
    Map<String, String> accountNames,
    Map<String, String> categories,
  ) {
    final labels = context.l10n;
    final row = item.row;
    final movement = row.movement;
    final choice = _selected[row.number];
    final state = item.state;
    final source =
        accountNames[item.mapping.accountId] ?? movement?.account ?? '';
    final destination =
        accountNames[item.mapping.targetId] ?? movement?.target ?? '';
    final category =
        categories[item.mapping.categoryId] ?? movement?.category ?? '';
    final editable =
        state == CsvReviewState.ready ||
        state == CsvReviewState.similar ||
        state == CsvReviewState.unresolved;
    final status = choice?.matchId != null
        ? labels.csvLinkedRow
        : choice?.acceptSimilar == true
        ? labels.csvSeparateRow
        : csvStateLabel(context, state);
    return Card(
      child: ListTile(
        title: Text(
          movement == null
              ? labels.csvLine(row.line)
              : '${csvTypeLabel(context, movement.type)} ${formatMoney(movement.amountMinor, movement.currency)}',
        ),
        subtitle: Text(
          [
            if (movement != null) labels.csvLine(row.line),
            status,
            if (item.suggestion case final suggestion?)
              suggestion.categoryId == null
                  ? labels.importRuleConflict
                  : labels.importRuleSuggested(
                      importRuleSummary(context, suggestion.matchedRules.first),
                    ),
            if (movement != null) ...[
              _date(context, movement.occurredAt),
              if (source.isNotEmpty)
                destination.isEmpty ? source : '$source → $destination',
              if (category.isNotEmpty) category,
              if (movement.note.isNotEmpty) movement.note,
            ],
            if (row.issue case final issue?) csvIssueLabel(context, issue),
          ].join(' · '),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: state == CsvReviewState.ready || choice != null
            ? Checkbox(
                value: choice != null,
                onChanged: _busy
                    ? null
                    : (include) => setState(() {
                        if (include == true && state == CsvReviewState.ready) {
                          _selected[row.number] = CsvSelection(
                            row.number,
                            item.mapping,
                          );
                        } else {
                          _selected.remove(row.number);
                        }
                      }),
              )
            : editable
            ? const Icon(Icons.chevron_right)
            : null,
        onTap: _busy
            ? null
            : editable
            ? () => _editRow(item)
            : row.issue != null && row.raw.isNotEmpty
            ? () => _showOriginal(row)
            : null,
      ),
    );
  }

  void _showOriginal(CsvImportRow row) => showDialog<void>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(context.l10n.csvLine(row.line)),
      content: SingleChildScrollView(
        child: SelectableText(
          [
            for (final item in row.raw.entries)
              if (item.value.isNotEmpty) '${item.key}  ${item.value}',
          ].join('\n'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialog),
          child: Text(context.l10n.close),
        ),
      ],
    ),
  );

  Future<void> _pickFile() => _loadStatement(pickStatementFile);

  Future<void> _paste() => _loadStatement(() => pasteStatement(context));

  Future<void> _loadStatement(Future<CsvImportFile?> Function() read) =>
      _start(() async {
        final file = await read();
        if (mounted && file != null) await _open(file);
      });

  Future<void> _open(CsvImportFile file) async {
    final rows = await ref
        .read(expenseRepositoryProvider)
        .previewCsvImport(file);
    if (!mounted) return;
    setState(() {
      _file = file;
      _mappings.clear();
      _rows = rows;
      _selected
        ..clear()
        ..addEntries(
          rows
              .where(
                (item) =>
                    item.state == CsvReviewState.ready &&
                    item.suggestion == null,
              )
              .map(
                (item) => MapEntry(
                  item.row.number,
                  CsvSelection(item.row.number, item.mapping),
                ),
              ),
        );
    });
  }

  Future<void> _refresh() => _start(() async {
    final rows = await ref
        .read(expenseRepositoryProvider)
        .previewCsvImport(_file!, mappings: _mappings);
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _selected.removeWhere((number, choice) {
        final item = rows.singleWhere((item) => item.row.number == number);
        return item.state != CsvReviewState.ready ||
            item.mapping != choice.mapping;
      });
    });
  });

  Future<void> _editRow(CsvReviewRow item) async {
    if (item.state == CsvReviewState.similar) {
      final decision =
          await showDialog<({bool changeMapping, CsvSelection? choice})>(
            context: context,
            builder: (_) => _CsvMatchDialog(item: item),
          );
      if (!mounted || decision == null) return;
      if (!decision.changeMapping) {
        final choice = decision.choice;
        setState(() {
          if (choice == null) {
            _selected.remove(item.row.number);
          } else {
            _selected[item.row.number] = choice;
          }
        });
        return;
      }
    }
    final mapping = await showDialog<CsvMapping>(
      context: context,
      builder: (_) => _CsvMappingDialog(item: item),
    );
    if (!mounted || mapping == null) return;
    CsvReviewRow? updated;
    await _start(() async {
      final newMappings = {..._mappings, item.row.number: mapping};
      final rows = await ref
          .read(expenseRepositoryProvider)
          .previewCsvImport(_file!, mappings: newMappings);
      if (!mounted) return;
      final edited = rows.singleWhere(
        (value) => value.row.number == item.row.number,
      );
      setState(() {
        _mappings[item.row.number] = mapping;
        _rows = rows;
        _selected.remove(item.row.number);
        if (edited.state == CsvReviewState.ready) {
          _selected[item.row.number] = CsvSelection(
            item.row.number,
            edited.mapping,
          );
        }
        updated = edited;
      });
    });
    if (mounted && updated?.state == CsvReviewState.similar) {
      await _editRow(updated!);
    }
  }

  Future<void> _commit() => _start(() async {
    final result = await ref
        .read(expenseRepositoryProvider)
        .commitCsvImport(_file!, _selected.values.toList(growable: false));
    if (!mounted) return;
    setState(() {
      _file = null;
      _rows = const [];
      _mappings.clear();
      _selected.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.csvBatchCounts(result.added, result.matched),
        ),
      ),
    );
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const CsvImportHistoryScreen()),
    );
  });

  Future<void> _start(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = csvErrorText(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _CsvMappingDialog extends ConsumerStatefulWidget {
  const _CsvMappingDialog({required this.item});
  final CsvReviewRow item;

  @override
  ConsumerState<_CsvMappingDialog> createState() => _CsvMappingDialogState();
}

class _CsvMappingDialogState extends ConsumerState<_CsvMappingDialog> {
  String? _account;
  String? _target;
  String? _category;

  @override
  void initState() {
    super.initState();
    _account = widget.item.mapping.accountId;
    _target = widget.item.mapping.targetId;
    _category = widget.item.mapping.categoryId;
  }

  @override
  Widget build(BuildContext context) {
    final movement = widget.item.row.movement!;
    final type = movement.type;
    final accounts =
        ref.watch(accountsProvider).asData?.value ?? const <LedgerAccount>[];
    final categories = csvNeedsCategory(type)
        ? ref
                  .watch(
                    type == LedgerTransactionType.expense
                        ? expenseCategoriesProvider
                        : incomeCategoriesProvider,
                  )
                  .asData
                  ?.value ??
              const <LedgerCategory>[]
        : const <LedgerCategory>[];
    final parents = {
      for (final category in categories)
        if (category.isParent) category.id: category,
    };
    final categoryOptions = {
      for (final category in categories)
        if (parents[category.parentId] case final parent?)
          category.id:
              '${DefaultLedgerLabels.category(context, parent)} / ${DefaultLedgerLabels.category(context, category)}',
    };
    Map<String, String> eligible({required bool target}) => {
      for (final account in accounts)
        if (account.currencyCode == movement.currency &&
            csvAccountAllowed(type, account.kind, target: target) &&
            (!target || account.id != _account))
          account.id: DefaultLedgerLabels.accountName(
            Localizations.localeOf(context),
            account.id,
            account.name,
          ),
    };
    final labels = context.l10n;
    final accountOptions = eligible(target: false);
    final targetOptions = eligible(target: true);
    final accountsReady =
        accountOptions.containsKey(_account) &&
        (!csvNeedsTarget(type) || targetOptions.containsKey(_target));
    return AlertDialog(
      title: Text(labels.csvLine(widget.item.row.line)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${csvTypeLabel(context, type)} ${formatMoney(movement.amountMinor, movement.currency)}',
            ),
            const SizedBox(height: 12),
            _Field(
              label: labels.csvSourceAccount,
              options: accountOptions,
              selected: _account,
              onChanged: (id) => setState(() {
                _account = id;
                if (_account == _target) _target = null;
              }),
            ),
            if (csvNeedsTarget(type))
              _Field(
                key: ValueKey(_account),
                label: labels.csvTargetAccount,
                options: targetOptions,
                selected: _target,
                onChanged: (id) => setState(() => _target = id),
              ),
            if (csvNeedsCategory(type))
              _Field(
                label: labels.secondaryCategory,
                options: categoryOptions,
                selected: _category,
                onChanged: (id) => setState(() => _category = id),
              ),
            if (accountOptions.isEmpty ||
                csvNeedsTarget(type) && targetOptions.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(labels.csvNoEligibleAccounts),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(labels.cancel),
        ),
        FilledButton(
          onPressed: accountsReady
              ? () => Navigator.pop(context, (
                  accountId: _account,
                  targetId: _target,
                  categoryId: _category,
                ))
              : null,
          child: Text(labels.csvReviewMapping),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final Map<String, String> options;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: options.containsKey(selected) ? selected : null,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final item in options.entries)
          DropdownMenuItem(
            value: item.key,
            child: Text(item.value, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: options.isEmpty ? null : onChanged,
    ),
  );
}

class _CsvMatchDialog extends StatelessWidget {
  const _CsvMatchDialog({required this.item});
  final CsvReviewRow item;

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final number = item.row.number;
    final canAdd =
        !csvNeedsCategory(item.row.movement!.type) ||
        item.mapping.categoryId != null;
    void choose(CsvSelection? choice) =>
        Navigator.pop(context, (changeMapping: false, choice: choice));
    return AlertDialog(
      title: Text(labels.csvSimilar),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(labels.csvSimilarHint),
            for (final candidate in item.matches)
              ListTile(
                title: Text(
                  [
                    candidate.accountName,
                    ?candidate.targetName,
                    _date(context, candidate.occurredAt),
                  ].join(' · '),
                ),
                subtitle: Text(
                  [
                    if (candidate.sameSourceRow) labels.csvEarlierSource,
                    candidate.note,
                  ].where((value) => value.isNotEmpty).join(' · '),
                ),
                trailing: candidate.canLink ? const Icon(Icons.link) : null,
                enabled: candidate.canLink,
                onTap: candidate.canLink
                    ? () => choose(
                        CsvSelection(
                          number,
                          item.mapping,
                          matchId: candidate.id,
                        ),
                      )
                    : null,
              ),
            if (!canAdd) Text(labels.csvCategoryForNew),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => choose(null),
          child: Text(labels.csvSkipRow),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, (
            changeMapping: true,
            choice: null as CsvSelection?,
          )),
          child: Text(labels.csvChangeMapping),
        ),
        FilledButton(
          onPressed: !canAdd
              ? null
              : () => choose(
                  CsvSelection(
                    number,
                    item.mapping,
                    reviewedMatchIds: item.matches
                        .map((candidate) => candidate.id)
                        .toSet(),
                  ),
                ),
          child: Text(labels.csvAddSeparately),
        ),
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(10),
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}

String _date(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
        .add_Hm()
        .format(date.toLocal());
