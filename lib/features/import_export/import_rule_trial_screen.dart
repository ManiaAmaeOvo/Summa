import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/import_export/csv_import.dart';
import 'package:summa/domain/import_export/import_category_rule.dart';
import 'package:summa/l10n/l10n.dart';

import 'csv_import_labels.dart';
import 'import_rule_labels.dart';
import 'statement_input.dart';

class ImportRuleTrialScreen extends ConsumerStatefulWidget {
  const ImportRuleTrialScreen({super.key, this.sample, this.draft});

  final CsvImportFile? sample;
  final ImportCategoryRule? draft;

  @override
  ConsumerState<ImportRuleTrialScreen> createState() =>
      _ImportRuleTrialScreenState();
}

class _ImportRuleTrialScreenState extends ConsumerState<ImportRuleTrialScreen> {
  CsvImportFile? _file;
  List<CsvRuleTrialRow> _rows = const [];
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.sample case final file?) _run(() async => file);
  }

  Future<void> _run(Future<CsvImportFile?> Function() read) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await read();
      if (!mounted || file == null) return;
      final rows = await ref
          .read(expenseRepositoryProvider)
          .previewImportRules(file, draft: widget.draft);
      if (!mounted) return;
      setState(() {
        _file = file;
        _rows = rows;
      });
    } on CsvImportException catch (error) {
      if (mounted) setState(() => _error = csvIssueLabel(context, error.issue));
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.csvOperationFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final categories = importRuleCategoryLabels(context, ref);
    final suggested = _rows
        .where(
          (item) =>
              item.explicitCategoryId == null &&
              item.suggestion?.categoryId != null,
        )
        .length;
    final conflicts = _rows
        .where(
          (item) =>
              item.explicitCategoryId == null &&
              item.suggestion != null &&
              item.suggestion!.categoryId == null,
        )
        .length;
    return Scaffold(
      appBar: AppBar(title: Text(labels.importRuleTrial)),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _rows.length + 1,
          itemBuilder: (context, index) {
            if (index > 0) return _result(_rows[index - 1], categories);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.draft == null
                      ? labels.importRuleTrialHint
                      : labels.importRuleDraftTrialHint,
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: _busy ? null : () => _run(pickStatementFile),
                      icon: const Icon(Icons.upload_file_outlined),
                      label: Text(labels.csvChooseFile),
                    ),
                    TextButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(() => pasteStatement(context)),
                      icon: const Icon(Icons.content_paste_outlined),
                      label: Text(labels.csvPaste),
                    ),
                  ],
                ),
                if (_busy) const LinearProgressIndicator(),
                if (_error case final error?)
                  Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (_file case final file?) ...[
                  Text(
                    file.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    labels.importRuleTrialSummary(
                      _rows.length,
                      suggested,
                      conflicts,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _result(CsvRuleTrialRow item, Map<String, String> categories) {
    final labels = context.l10n;
    String category(String id) =>
        categories[id] ?? labels.importRuleUnavailable;
    final movement = item.row.movement;
    final suggestion = item.suggestion;
    final issue = item.row.issue;
    final text = switch ((item.explicitCategoryId, suggestion)) {
      (final id?, _) => labels.importRuleTrialExplicit(category(id)),
      (_, final hit?) =>
        hit.categoryId == null
            ? labels.importRuleConflict
            : labels.importRuleTrialSuggested(category(hit.categoryId!)),
      _ =>
        issue != null
            ? csvIssueLabel(context, issue)
            : movement != null && !csvNeedsCategory(movement.type)
            ? labels.importRuleTrialUnsupported
            : labels.importRuleTrialNoMatch,
    };
    final title = [
      labels.csvLine(item.row.line),
      if (movement != null)
        formatMoney(movement.amountMinor, movement.currency),
      if (item.row.raw['merchant'] case final merchant?
          when merchant.isNotEmpty)
        merchant,
    ].join(' · ');
    return Card(
      child: suggestion == null
          ? ListTile(title: Text(title), subtitle: Text(text))
          : ExpansionTile(
              title: Text(title),
              subtitle: Text(text),
              children: [
                for (final rule in suggestion.matchedRules)
                  ListTile(
                    title: Text(importRuleSummary(context, rule)),
                    subtitle: Text(
                      [
                        category(rule.categoryId),
                        labels.importRulePriorityValue(rule.priority),
                        if (rule.priority == suggestion.priority)
                          labels.importRuleTopPriority,
                        if (identical(rule, widget.draft))
                          labels.importRuleDraft,
                      ].join(' · '),
                    ),
                  ),
              ],
            ),
    );
  }
}
