import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ledger_pro/app/providers.dart';
import 'package:ledger_pro/core/money/money.dart';
import 'package:ledger_pro/domain/accounts/ledger_account.dart';
import 'package:ledger_pro/domain/categories/ledger_category.dart';
import 'package:ledger_pro/domain/import_export/ledger_import.dart';
import 'package:ledger_pro/domain/transactions/expense_record.dart';
import 'package:ledger_pro/domain/transactions/expense_repository.dart';

class StructuredImportScreen extends ConsumerStatefulWidget {
  const StructuredImportScreen({super.key});

  @override
  ConsumerState<StructuredImportScreen> createState() =>
      _StructuredImportScreenState();
}

class _StructuredImportScreenState
    extends ConsumerState<StructuredImportScreen> {
  final _controller = TextEditingController();
  List<LedgerImportDraft>? _drafts;
  String? _error;
  var _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).asData?.value;
    final expenses = ref.watch(expenseCategoriesProvider).asData?.value;
    final incomes = ref.watch(incomeCategoriesProvider).asData?.value;
    final ready = accounts != null && expenses != null && incomes != null;
    final drafts = _drafts;
    return Scaffold(
      appBar: AppBar(
        title: Text(drafts == null ? '代码块导入' : '是否导入 ${drafts.length} 条账单？'),
      ),
      body: SafeArea(
        child: drafts == null
            ? _buildInput(context, ready, accounts, expenses, incomes)
            : _buildPreview(context, drafts, accounts!, expenses!, incomes!),
      ),
    );
  }

  Widget _buildInput(
    BuildContext context,
    bool ready,
    List<LedgerAccount>? accounts,
    List<LedgerCategory>? expenses,
    List<LedgerCategory>? incomes,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '粘贴单笔、数组或 schema_version 1 批量 JSON。金额必须是字符串，分类使用“主分类/子分类”。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              expands: true,
              minLines: null,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                labelText: 'JSON 代码块',
                alignLabelWithHint: true,
                hintText: '```json\n{ ... }\n```',
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      const ClipboardData(text: ledgerImportTemplate),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('导入模板已复制')));
                    }
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('复制模板'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: ready
                      ? () => _parse(accounts!, expenses!, incomes!)
                      : null,
                  icon: const Icon(Icons.preview_outlined),
                  label: Text(ready ? '解析并预览' : '正在加载…'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(
    BuildContext context,
    List<LedgerImportDraft> drafts,
    List<LedgerAccount> accounts,
    List<LedgerCategory> expenses,
    List<LedgerCategory> incomes,
  ) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: drafts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final draft = drafts[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(
                    '${_typeLabel(draft.type)}  ${formatCny(draft.amountMinor)}',
                  ),
                  subtitle: Text(
                    [
                      DateFormat('yyyy-MM-dd HH:mm').format(draft.occurredAt),
                      if (draft.categoryPath != null) draft.categoryPath!,
                      draft.targetAccountName == null
                          ? draft.accountName
                          : '${draft.accountName} → ${draft.targetAccountName}',
                      if (draft.accountIsNew)
                        '将新建${_accountKindLabel(draft.accountKind)}账户：${draft.accountName}',
                      if (draft.targetAccountIsNew)
                        '将新建${_accountKindLabel(draft.targetAccountKind!)}账户：${draft.targetAccountName}',
                      if (draft.note.isNotEmpty) draft.note,
                    ].join(' · '),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editDraft(index, draft, accounts, expenses, incomes);
                      } else {
                        setState(() => drafts.removeAt(index));
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('编辑')),
                      PopupMenuItem(value: 'remove', child: Text('移除此条')),
                    ],
                  ),
                  onTap: () =>
                      _editDraft(index, draft, accounts, expenses, incomes),
                ),
              );
            },
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () => setState(() {
                          _drafts = null;
                          _error = null;
                        }),
                  child: const Text('返回修改代码'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _saving || drafts.isEmpty ? null : _confirmImport,
                  child: Text(_saving ? '导入中…' : '确认导入 ${drafts.length} 条'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _parse(
    List<LedgerAccount> accounts,
    List<LedgerCategory> expenses,
    List<LedgerCategory> incomes,
  ) {
    try {
      final drafts = parseLedgerImport(
        _controller.text,
        accounts: accounts,
        expenseCategories: expenses,
        incomeCategories: incomes,
      );
      setState(() {
        _drafts = drafts;
        _error = null;
      });
    } on LedgerImportException catch (error) {
      setState(() => _error = error.message);
    }
  }

  Future<void> _editDraft(
    int index,
    LedgerImportDraft draft,
    List<LedgerAccount> accounts,
    List<LedgerCategory> expenses,
    List<LedgerCategory> incomes,
  ) async {
    final edited = await showDialog<LedgerImportDraft>(
      context: context,
      builder: (_) => _DraftEditorDialog(
        draft: draft,
        accounts: accounts,
        categories: draft.type == LedgerTransactionType.expense
            ? expenses
            : incomes,
      ),
    );
    if (edited != null && mounted) {
      setState(() => _drafts![index] = edited);
    }
  }

  Future<void> _confirmImport() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(expenseRepositoryProvider).importTransactions(_drafts!);
      if (!mounted) return;
      final count = _drafts!.length;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text('已导入 $count 条账单')));
    } on TransactionRuleException catch (error) {
      if (mounted) setState(() => _error = '整批未导入：${error.message}');
    } catch (_) {
      if (mounted) setState(() => _error = '整批未导入，请检查内容后重试');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _DraftEditorDialog extends StatefulWidget {
  const _DraftEditorDialog({
    required this.draft,
    required this.accounts,
    required this.categories,
  });

  final LedgerImportDraft draft;
  final List<LedgerAccount> accounts;
  final List<LedgerCategory> categories;

  @override
  State<_DraftEditorDialog> createState() => _DraftEditorDialogState();
}

class _DraftEditorDialogState extends State<_DraftEditorDialog> {
  late final TextEditingController _amount;
  late final TextEditingController _time;
  late final TextEditingController _note;
  late String _accountId;
  String? _targetId;
  String? _categoryId;
  String? _error;

  List<LedgerAccount> get _accounts {
    final result = [...widget.accounts];
    if (widget.draft.accountIsNew) {
      result.add(
        LedgerAccount(
          id: widget.draft.accountId,
          name: widget.draft.accountName,
          kind: widget.draft.accountKind,
        ),
      );
    }
    if (widget.draft.targetAccountIsNew &&
        !result.any((item) => item.id == widget.draft.targetAccountId)) {
      result.add(
        LedgerAccount(
          id: widget.draft.targetAccountId!,
          name: widget.draft.targetAccountName!,
          kind: widget.draft.targetAccountKind!,
        ),
      );
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: (widget.draft.amountMinor / 100).toStringAsFixed(2),
    );
    _time = TextEditingController(
      text: widget.draft.occurredAt.toIso8601String(),
    );
    _note = TextEditingController(text: widget.draft.note);
    _accountId = widget.draft.accountId;
    _targetId = widget.draft.targetAccountId;
    _categoryId = widget.draft.categoryId;
  }

  @override
  void dispose() {
    _amount.dispose();
    _time.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.draft.type;
    final accounts = _accounts;
    final primaryAccounts = _accountsForPrimary(type, accounts);
    final targetAccounts = _accountsForTarget(type, accounts);
    final children = widget.categories.where((item) => !item.isParent).toList();
    return AlertDialog(
      title: Text('编辑${_typeLabel(type)}记录'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '金额',
                prefixText: '¥ ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _time,
              decoration: const InputDecoration(labelText: 'ISO 8601 时间'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _accountId,
              decoration: InputDecoration(
                labelText: type == LedgerTransactionType.borrowing
                    ? '负债账户'
                    : '账户',
              ),
              items: [
                for (final account in primaryAccounts)
                  DropdownMenuItem(
                    value: account.id,
                    child: Text(account.name),
                  ),
              ],
              onChanged: (value) => setState(() => _accountId = value!),
            ),
            if (targetAccounts.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _targetId,
                decoration: const InputDecoration(labelText: '目标账户'),
                items: [
                  for (final account in targetAccounts)
                    DropdownMenuItem(
                      value: account.id,
                      child: Text(account.name),
                    ),
                ],
                onChanged: (value) => setState(() => _targetId = value),
              ),
            ],
            if (type == LedgerTransactionType.expense ||
                type == LedgerTransactionType.income) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: '分类'),
                items: [
                  for (final child in children)
                    DropdownMenuItem(
                      value: child.id,
                      child: Text(_categoryPath(child, widget.categories)),
                    ),
                ],
                onChanged: (value) => setState(() => _categoryId = value),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLength: 200,
              decoration: const InputDecoration(labelText: '备注'),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _save, child: const Text('保存修改')),
      ],
    );
  }

  void _save() {
    try {
      final amount = parseCnyMinorUnits(_amount.text);
      final time = DateTime.tryParse(_time.text.trim());
      if (time == null) throw const LedgerImportException('时间格式不正确');
      final account = _accounts.singleWhere((item) => item.id == _accountId);
      final target = _targetId == null
          ? null
          : _accounts.singleWhere((item) => item.id == _targetId);
      final category = _categoryId == null
          ? null
          : widget.categories.singleWhere((item) => item.id == _categoryId);
      Navigator.pop(
        context,
        widget.draft.copyWith(
          amountMinor: amount,
          occurredAt: time,
          accountId: account.id,
          accountName: account.name,
          accountKind: account.kind,
          accountIsNew: account.id.startsWith('__new__:'),
          targetAccountId: target?.id,
          targetAccountName: target?.name,
          targetAccountKind: target?.kind,
          targetAccountIsNew: target?.id.startsWith('__new__:') ?? false,
          categoryId: category?.id,
          categoryPath: category == null
              ? null
              : _categoryPath(category, widget.categories),
          note: _note.text.trim(),
        ),
      );
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }
}

List<LedgerAccount> _accountsForPrimary(
  LedgerTransactionType type,
  List<LedgerAccount> accounts,
) => switch (type) {
  LedgerTransactionType.borrowing =>
    accounts.where((item) => item.group == AccountGroup.liability).toList(),
  LedgerTransactionType.repayment =>
    accounts.where((item) => item.group == AccountGroup.personalAsset).toList(),
  LedgerTransactionType.transfer =>
    accounts.where((item) => item.group == AccountGroup.personalAsset).toList(),
  _ => accounts,
};

List<LedgerAccount> _accountsForTarget(
  LedgerTransactionType type,
  List<LedgerAccount> accounts,
) => switch (type) {
  LedgerTransactionType.borrowing =>
    accounts.where((item) => item.group == AccountGroup.personalAsset).toList(),
  LedgerTransactionType.repayment =>
    accounts.where((item) => item.group == AccountGroup.liability).toList(),
  LedgerTransactionType.transfer =>
    accounts.where((item) => item.group == AccountGroup.personalAsset).toList(),
  _ => const [],
};

String _categoryPath(LedgerCategory child, List<LedgerCategory> categories) {
  final parent = categories.singleWhere((item) => item.id == child.parentId);
  return '${parent.name}/${child.name}';
}

String _typeLabel(LedgerTransactionType type) => switch (type) {
  LedgerTransactionType.expense => '支出',
  LedgerTransactionType.income => '收入',
  LedgerTransactionType.transfer => '转账',
  LedgerTransactionType.borrowing => '借入',
  LedgerTransactionType.repayment => '还款',
};

String _accountKindLabel(AccountKind kind) => switch (kind) {
  AccountKind.cash => '现金',
  AccountKind.bank => '银行卡',
  AccountKind.wallet => '电子钱包',
  AccountKind.creditLine => '负债',
  AccountKind.entrustedFunds => '委托/授权资金',
};
