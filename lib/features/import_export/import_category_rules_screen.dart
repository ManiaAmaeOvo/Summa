import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/domain/categories/ledger_category.dart';
import 'package:summa/domain/import_export/import_category_rule.dart';
import 'package:summa/l10n/default_ledger_labels.dart';
import 'package:summa/l10n/l10n.dart';

class ImportCategoryRulesScreen extends ConsumerWidget {
  const ImportCategoryRulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = context.l10n;
    final options = _categories(context, ref);
    return Scaffold(
      appBar: AppBar(title: Text(labels.importCategoryRules)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context),
        icon: const Icon(Icons.add),
        label: Text(labels.importRuleAdd),
      ),
      body: ref
          .watch(importCategoryRulesProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(importCategoryRulesProvider),
                child: Text(labels.retry),
              ),
            ),
            data: (rules) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                Text(labels.importRuleInstructions),
                if (rules.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(labels.importRuleEmpty),
                  ),
                for (final rule in rules)
                  Card(
                    child: ListTile(
                      title: Text(
                        '${_fieldLabel(context, rule.field)} · ${rule.keyword}',
                      ),
                      subtitle: Text(
                        [
                          options[rule.categoryId] ??
                              labels.importRuleUnavailable,
                          labels.importRulePriorityValue(rule.priority),
                          if (!rule.enabled) labels.importRuleDisabled,
                        ].join(' · '),
                      ),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _open(context, rule),
                    ),
                  ),
              ],
            ),
          ),
    );
  }

  void _open(BuildContext context, [ImportCategoryRule? rule]) =>
      showDialog<void>(
        context: context,
        builder: (_) => _RuleEditor(rule: rule),
      );
}

class _RuleEditor extends ConsumerStatefulWidget {
  const _RuleEditor({this.rule});
  final ImportCategoryRule? rule;

  @override
  ConsumerState<_RuleEditor> createState() => _RuleEditorState();
}

class _RuleEditorState extends ConsumerState<_RuleEditor> {
  late final TextEditingController _keyword;
  late final TextEditingController _priority;
  late ImportRuleField _field;
  String? _category;
  late bool _enabled;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    _field = rule?.field ?? ImportRuleField.description;
    _keyword = TextEditingController(text: rule?.keyword);
    _priority = TextEditingController(text: (rule?.priority ?? 100).toString());
    _category = rule?.categoryId;
    _enabled = rule?.enabled ?? true;
  }

  @override
  void dispose() {
    _keyword.dispose();
    _priority.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final priority = int.tryParse(_priority.text.trim());
    if (_keyword.text.trim().isEmpty ||
        priority == null ||
        priority < 0 ||
        priority > 9999) {
      setState(() => _error = context.l10n.importRuleInvalid);
      return;
    }
    await _mutate(
      () => ref
          .read(expenseRepositoryProvider)
          .saveImportRule(
            id: widget.rule?.id,
            field: _field,
            keyword: _keyword.text,
            categoryId: _category!,
            priority: priority,
            enabled: _enabled,
          ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(context.l10n.importRuleDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _mutate(
      () =>
          ref.read(expenseRepositoryProvider).deleteImportRule(widget.rule!.id),
    );
  }

  Future<void> _mutate(Future<void> Function() action) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = context.l10n.saveFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final options = _categories(context, ref);
    return AlertDialog(
      title: Text(
        widget.rule == null ? labels.importRuleAdd : labels.importRuleEdit,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ImportRuleField>(
              initialValue: _field,
              decoration: InputDecoration(
                labelText: labels.importRuleFieldLabel,
              ),
              items: [
                for (final field in ImportRuleField.values)
                  DropdownMenuItem(
                    value: field,
                    child: Text(_fieldLabel(context, field)),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (field) {
                      if (field != null) setState(() => _field = field);
                    },
            ),
            TextField(
              controller: _keyword,
              maxLength: 80,
              decoration: InputDecoration(labelText: labels.importRuleKeyword),
            ),
            DropdownButtonFormField<String>(
              initialValue: options.containsKey(_category) ? _category : null,
              isExpanded: true,
              decoration: InputDecoration(labelText: labels.secondaryCategory),
              items: [
                for (final option in options.entries)
                  DropdownMenuItem(
                    value: option.key,
                    child: Text(option.value, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (category) => setState(() => _category = category),
            ),
            TextField(
              controller: _priority,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: labels.importRulePriority,
                helperText: labels.importRulePriorityHint,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(labels.importRuleEnabled),
              value: _enabled,
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _enabled = value),
            ),
            if (_error case final error?)
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        if (widget.rule != null)
          TextButton(
            onPressed: _saving ? null : _delete,
            child: Text(labels.delete),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(labels.cancel),
        ),
        FilledButton(
          onPressed: _saving || !options.containsKey(_category) ? null : _save,
          child: Text(_saving ? labels.saving : labels.save),
        ),
      ],
    );
  }
}

Map<String, String> _categories(BuildContext context, WidgetRef ref) {
  final options = <String, String>{};
  for (final (label, categories) in [
    (
      context.l10n.expense,
      ref.watch(expenseCategoriesProvider).asData?.value ??
          const <LedgerCategory>[],
    ),
    (
      context.l10n.income,
      ref.watch(incomeCategoriesProvider).asData?.value ??
          const <LedgerCategory>[],
    ),
  ]) {
    final parents = {
      for (final item in categories)
        if (item.isParent) item.id: item,
    };
    for (final child in categories) {
      if (parents[child.parentId] case final parent?) {
        options[child.id] =
            '$label · ${DefaultLedgerLabels.category(context, parent)} / ${DefaultLedgerLabels.category(context, child)}';
      }
    }
  }
  return options;
}

String _fieldLabel(BuildContext context, ImportRuleField field) =>
    switch (field) {
      ImportRuleField.merchant => context.l10n.importRuleMerchant,
      ImportRuleField.description => context.l10n.importRuleDescription,
      ImportRuleField.paymentChannel => context.l10n.importRulePayment,
      ImportRuleField.source => context.l10n.importRuleSource,
      ImportRuleField.account => context.l10n.csvSourceAccount,
    };
