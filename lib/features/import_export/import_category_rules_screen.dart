import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/import_export/csv_import.dart';
import 'package:summa/domain/import_export/import_category_rule.dart';
import 'package:summa/l10n/l10n.dart';

import 'import_rule_labels.dart';
import 'import_rule_trial_screen.dart';

class ImportCategoryRulesScreen extends ConsumerWidget {
  const ImportCategoryRulesScreen({super.key, this.sample});

  final CsvImportFile? sample;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = context.l10n;
    final options = importRuleCategoryLabels(context, ref);
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
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    icon: const Icon(Icons.play_arrow_outlined),
                    label: Text(labels.importRuleTrial),
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImportRuleTrialScreen(sample: sample),
                      ),
                    ),
                  ),
                ),
                if (rules.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(labels.importRuleEmpty),
                  ),
                for (final rule in rules)
                  Card(
                    child: ListTile(
                      title: Text(
                        options[rule.categoryId] ??
                            labels.importRuleUnavailable,
                      ),
                      subtitle: Text(
                        [
                          [
                            labels.importRulePriorityValue(rule.priority),
                            if (rule.conditions.length > 1)
                              importRuleModeLabel(context, rule.mode),
                            if (!rule.enabled) labels.importRuleDisabled,
                          ].join(' · '),
                          importRuleSummary(context, rule),
                        ].join('\n'),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
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
        builder: (_) => _RuleEditor(rule: rule, sample: sample),
      );
}

class _RuleEditor extends ConsumerStatefulWidget {
  const _RuleEditor({this.rule, this.sample});
  final ImportCategoryRule? rule;
  final CsvImportFile? sample;

  @override
  ConsumerState<_RuleEditor> createState() => _RuleEditorState();
}

class _RuleEditorState extends ConsumerState<_RuleEditor> {
  late final List<_ConditionDraft> _conditions;
  late final TextEditingController _priority;
  late ImportRuleMode _mode;
  String? _category;
  late bool _enabled;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    _conditions = [
      if (rule == null)
        _ConditionDraft()
      else
        for (final condition in rule.conditions) _ConditionDraft(condition),
    ];
    _priority = TextEditingController(text: (rule?.priority ?? 100).toString());
    _mode = rule?.mode ?? ImportRuleMode.all;
    _category = rule?.categoryId;
    _enabled = rule?.enabled ?? true;
  }

  @override
  void dispose() {
    for (final condition in _conditions) {
      condition.value.dispose();
    }
    _priority.dispose();
    super.dispose();
  }

  ImportCategoryRule? _draft() {
    final rule = ImportCategoryRule(
      id: widget.rule?.id ?? '',
      conditions: [for (final draft in _conditions) draft.condition],
      categoryId: _category ?? '',
      priority: int.tryParse(_priority.text.trim()) ?? -1,
      mode: _mode,
      enabled: _enabled,
    );
    if (!rule.isValid) {
      setState(() => _error = context.l10n.importRuleInvalid);
      return null;
    }
    setState(() => _error = null);
    return rule;
  }

  void _trial() {
    final draft = _draft();
    if (draft == null) return;
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ImportRuleTrialScreen(sample: widget.sample, draft: draft),
      ),
    );
  }

  Future<void> _save() async {
    final draft = _draft();
    if (draft == null) return;
    await _mutate(
      () => ref
          .read(expenseRepositoryProvider)
          .saveImportRule(
            id: widget.rule?.id,
            conditions: draft.conditions,
            mode: draft.mode,
            categoryId: draft.categoryId,
            priority: draft.priority,
            enabled: draft.enabled,
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
    final options = importRuleCategoryLabels(context, ref);
    final canApply = !_saving && options.containsKey(_category);
    return AlertDialog(
      title: Text(
        widget.rule == null ? labels.importRuleAdd : labels.importRuleEdit,
      ),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 8),
          TextField(
            controller: _priority,
            enabled: !_saving,
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
          if (_conditions.length > 1)
            DropdownButtonFormField<ImportRuleMode>(
              initialValue: _mode,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: labels.importRuleMatchMode,
              ),
              items: [
                for (final mode in ImportRuleMode.values)
                  DropdownMenuItem(
                    value: mode,
                    child: Text(importRuleModeLabel(context, mode)),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (mode) {
                      if (mode != null) setState(() => _mode = mode);
                    },
            ),
          for (final condition in _conditions)
            _ConditionEditor(
              key: ObjectKey(condition),
              draft: condition,
              enabled: !_saving,
              onRemove: _conditions.length > 1 && !_saving
                  ? () {
                      setState(() => _conditions.remove(condition));
                      // Leave disposal until the removed text field has unmounted.
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => condition.value.dispose(),
                      );
                    }
                  : null,
            ),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: Text(labels.importRuleAddCondition),
            onPressed: _saving
                ? null
                : () => setState(() => _conditions.add(_ConditionDraft())),
          ),
        ],
      ),
      actions: [
        if (_error case final error?)
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (widget.rule != null)
          TextButton(
            onPressed: _saving ? null : _delete,
            child: Text(labels.delete),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(labels.cancel),
        ),
        TextButton(
          onPressed: canApply ? _trial : null,
          child: Text(labels.importRuleTrial),
        ),
        FilledButton(
          onPressed: canApply ? _save : null,
          child: Text(_saving ? labels.saving : labels.save),
        ),
      ],
    );
  }
}

class _ConditionDraft {
  _ConditionDraft([ImportRuleCondition? condition])
    : field = condition?.field ?? ImportRuleField.description,
      operator = condition?.operator ?? ImportRuleOperator.contains,
      currency = condition?.currency ?? defaultCurrency,
      value = TextEditingController(text: condition?.value);

  ImportRuleField field;
  ImportRuleOperator operator;
  String currency;
  final TextEditingController value;

  ImportRuleCondition get condition => ImportRuleCondition(
    field: field,
    operator: operator,
    value: value.text.trim(),
    currency: field == ImportRuleField.amount ? currency : null,
  );
}

class _ConditionEditor extends StatefulWidget {
  const _ConditionEditor({
    super.key,
    required this.draft,
    required this.enabled,
    this.onRemove,
  });

  final _ConditionDraft draft;
  final bool enabled;
  final VoidCallback? onRemove;

  @override
  State<_ConditionEditor> createState() => _ConditionEditorState();
}

class _ConditionEditorState extends State<_ConditionEditor> {
  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final draft = widget.draft;
    final operators = ImportRuleCondition.operatorsFor(draft.field);
    final amount = draft.field == ImportRuleField.amount;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ImportRuleField>(
                    initialValue: draft.field,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: labels.importRuleFieldLabel,
                    ),
                    items: [
                      for (final field in ImportRuleField.values)
                        DropdownMenuItem(
                          value: field,
                          child: Text(
                            importRuleFieldLabel(context, field),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: !widget.enabled
                        ? null
                        : (field) {
                            if (field == null) return;
                            setState(() {
                              draft.field = field;
                              final allowed = ImportRuleCondition.operatorsFor(
                                field,
                              );
                              if (!allowed.contains(draft.operator)) {
                                draft.operator = allowed.first;
                              }
                            });
                          },
                  ),
                ),
                if (widget.onRemove != null)
                  IconButton(
                    tooltip: labels.importRuleRemoveCondition,
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ImportRuleOperator>(
              key: ValueKey(amount),
              initialValue: draft.operator,
              isExpanded: true,
              decoration: InputDecoration(labelText: labels.importRuleOperator),
              items: [
                for (final operator in operators)
                  DropdownMenuItem(
                    value: operator,
                    child: Text(importRuleOperatorLabel(context, operator)),
                  ),
              ],
              onChanged: !widget.enabled
                  ? null
                  : (operator) {
                      if (operator != null) {
                        setState(() => draft.operator = operator);
                      }
                    },
            ),
            if (amount) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: draft.currency,
                isExpanded: true,
                decoration: InputDecoration(labelText: labels.currencyLabel),
                items: [
                  for (final code in currencyMinorDigits.keys)
                    DropdownMenuItem(value: code, child: Text(code)),
                ],
                onChanged: !widget.enabled
                    ? null
                    : (code) {
                        if (code != null) setState(() => draft.currency = code);
                      },
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: draft.value,
              enabled: widget.enabled,
              maxLength: 80,
              keyboardType: amount
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              decoration: InputDecoration(
                labelText: amount ? labels.amount : labels.importRuleKeyword,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
