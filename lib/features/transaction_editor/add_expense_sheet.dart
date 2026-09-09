import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ledger_pro/app/providers.dart';
import 'package:ledger_pro/core/money/money.dart';
import 'package:ledger_pro/domain/accounts/ledger_account.dart';
import 'package:ledger_pro/domain/categories/ledger_category.dart';
import 'package:ledger_pro/domain/transactions/expense_record.dart';
import 'package:ledger_pro/domain/transactions/expense_repository.dart';
import 'package:ledger_pro/features/accounts/account_overview_screen.dart';

class TransactionEditorSheet extends ConsumerStatefulWidget {
  const TransactionEditorSheet({super.key, this.record});

  final LedgerRecord? record;

  @override
  ConsumerState<TransactionEditorSheet> createState() =>
      _TransactionEditorSheetState();
}

class _TransactionEditorSheetState
    extends ConsumerState<TransactionEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late LedgerTransactionType _type;
  DateTime _occurredAt = DateTime.now();
  String? _parentCategoryId;
  String? _categoryId;
  String? _accountId;
  String? _targetAccountId;
  String? _submissionError;
  bool _isSaving = false;

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _type = record?.type ?? LedgerTransactionType.expense;
    if (record == null) return;
    _amountController.text = _editableAmount(record.amountMinor);
    _noteController.text = record.note;
    _occurredAt = record.occurredAt;
    _parentCategoryId = record.parentCategoryId;
    _categoryId = record.categoryId;
    _accountId = record.accountId;
    _targetAccountId = record.targetAccountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = switch (_type) {
      LedgerTransactionType.expense => ref.watch(expenseCategoriesProvider),
      LedgerTransactionType.income => ref.watch(incomeCategoriesProvider),
      _ => null,
    };
    final accounts = ref.watch(accountsProvider);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    _isEditing ? '编辑记录' : '记一笔',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: '关闭',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<LedgerTransactionType>(
                  segments: const [
                    ButtonSegment(
                      value: LedgerTransactionType.expense,
                      label: Text('支出'),
                    ),
                    ButtonSegment(
                      value: LedgerTransactionType.income,
                      label: Text('收入'),
                    ),
                    ButtonSegment(
                      value: LedgerTransactionType.transfer,
                      label: Text('转账'),
                    ),
                    ButtonSegment(
                      value: LedgerTransactionType.borrowing,
                      label: Text('借入'),
                    ),
                    ButtonSegment(
                      value: LedgerTransactionType.repayment,
                      label: Text('还款'),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: _isSaving
                      ? null
                      : (selection) => _changeType(selection.single),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                autofocus: !_isEditing,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(
                  labelText: '金额',
                  prefixText: '¥ ',
                  hintText: '0.00',
                ),
                validator: (value) {
                  try {
                    parseCnyMinorUnits(value ?? '');
                    return null;
                  } on MoneyInputException catch (error) {
                    return error.message;
                  }
                },
              ),
              if (categories != null) ...[
                const SizedBox(height: 16),
                categories.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const Text('分类加载失败'),
                  data: _buildCategoryFields,
                ),
              ],
              const SizedBox(height: 16),
              accounts.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('账户加载失败'),
                data: _buildAccountFields,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickDateTime,
                icon: const Icon(Icons.schedule),
                label: Text(
                  DateFormat('yyyy年MM月dd日 HH:mm').format(_occurredAt),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: '备注（可选）',
                  hintText: _noteHint,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _submissionError == null
                    ? const SizedBox.shrink()
                    : Container(
                        key: ValueKey(_submissionError),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _submissionError!,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_isEditing ? '保存修改' : '保存记录'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _noteHint => switch (_type) {
    LedgerTransactionType.expense => '这笔钱花在了哪里？',
    LedgerTransactionType.income => '这笔钱来自哪里？',
    LedgerTransactionType.transfer => '例如：支付宝转入微信',
    LedgerTransactionType.borrowing => '例如：向朋友借款',
    LedgerTransactionType.repayment => '例如：归还朋友欠款',
  };

  void _changeType(LedgerTransactionType value) {
    setState(() {
      _type = value;
      _parentCategoryId = null;
      _categoryId = null;
      _accountId = null;
      _targetAccountId = null;
      _submissionError = null;
    });
  }

  Widget _buildCategoryFields(List<LedgerCategory> categories) {
    final parents = categories.where((category) => category.isParent).toList();
    final parentId = parents.any((item) => item.id == _parentCategoryId)
        ? _parentCategoryId
        : parents.firstOrNull?.id;
    final children = categories
        .where((category) => category.parentId == parentId)
        .toList();
    final categoryId = children.any((item) => item.id == _categoryId)
        ? _categoryId
        : children.firstOrNull?.id;
    _parentCategoryId = parentId;
    _categoryId = categoryId;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            key: ValueKey('parent-${_type.name}'),
            initialValue: parentId,
            decoration: const InputDecoration(labelText: '主分类'),
            items: [
              for (final parent in parents)
                DropdownMenuItem(value: parent.id, child: Text(parent.name)),
            ],
            onChanged: (value) => setState(() {
              _parentCategoryId = value;
              _categoryId = null;
            }),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            key: ValueKey('$parentId-${_type.name}'),
            initialValue: categoryId,
            decoration: const InputDecoration(labelText: '子分类'),
            items: [
              for (final child in children)
                DropdownMenuItem(value: child.id, child: Text(child.name)),
            ],
            onChanged: (value) => setState(() => _categoryId = value),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountFields(List<LedgerAccount> accounts) {
    final selectable = _withOriginalArchivedAccounts(accounts);
    return switch (_type) {
      LedgerTransactionType.expense => _singleAccountField(
        selectable,
        label: '付款账户',
      ),
      LedgerTransactionType.income => _singleAccountField(
        selectable,
        label: '收入计入账户',
      ),
      LedgerTransactionType.borrowing => _borrowingFields(selectable),
      LedgerTransactionType.repayment => _repaymentFields(selectable),
      LedgerTransactionType.transfer => _transferFields(selectable),
    };
  }

  List<LedgerAccount> _withOriginalArchivedAccounts(
    List<LedgerAccount> accounts,
  ) {
    final result = [...accounts];
    final record = widget.record;
    if (record == null) return result;
    if (!result.any((item) => item.id == record.accountId)) {
      result.add(
        LedgerAccount(
          id: record.accountId,
          name: '${record.accountName}（已停用）',
          kind: AccountKind.values.byName(record.accountKind),
        ),
      );
    }
    if (record.targetAccountId != null &&
        !result.any((item) => item.id == record.targetAccountId)) {
      result.add(
        LedgerAccount(
          id: record.targetAccountId!,
          name: '${record.targetAccountName}（已停用）',
          kind: AccountKind.values.byName(record.targetAccountKind!),
        ),
      );
    }
    return result;
  }

  Widget _singleAccountField(
    List<LedgerAccount> accounts, {
    required String label,
  }) {
    final accountId = accounts.any((item) => item.id == _accountId)
        ? _accountId
        : accounts.firstOrNull?.id;
    _accountId = accountId;
    _targetAccountId = null;
    return _accountDropdown(
      key: ValueKey('${_type.name}-account'),
      accounts: accounts,
      value: accountId,
      label: label,
      onChanged: (value) => setState(() => _accountId = value),
    );
  }

  Widget _borrowingFields(List<LedgerAccount> accounts) {
    final liabilities = accounts
        .where((item) => item.group == AccountGroup.liability)
        .toList();
    final assets = accounts
        .where((item) => item.group == AccountGroup.personalAsset)
        .toList();
    _accountId = liabilities.any((item) => item.id == _accountId)
        ? _accountId
        : liabilities.firstOrNull?.id;
    _targetAccountId = assets.any((item) => item.id == _targetAccountId)
        ? _targetAccountId
        : assets.firstOrNull?.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _accountDropdown(
          key: const ValueKey('borrowing-source'),
          accounts: liabilities,
          value: _accountId,
          label: '负债账户',
          onChanged: (value) => setState(() => _accountId = value),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) =>
                  const AddAccountDialog(initialKind: AccountKind.creditLine),
            ),
            icon: const Icon(Icons.add),
            label: const Text('快捷添加负债账户'),
          ),
        ),
        const SizedBox(height: 4),
        _accountDropdown(
          key: const ValueKey('borrowing-target'),
          accounts: assets,
          value: _targetAccountId,
          label: '资金存入账户',
          onChanged: (value) => setState(() => _targetAccountId = value),
        ),
      ],
    );
  }

  Widget _repaymentFields(List<LedgerAccount> accounts) {
    final assets = accounts
        .where((item) => item.group == AccountGroup.personalAsset)
        .toList();
    final liabilities = accounts
        .where((item) => item.group == AccountGroup.liability)
        .toList();
    _accountId = assets.any((item) => item.id == _accountId)
        ? _accountId
        : assets.firstOrNull?.id;
    _targetAccountId = liabilities.any((item) => item.id == _targetAccountId)
        ? _targetAccountId
        : liabilities.firstOrNull?.id;
    return Column(
      children: [
        _accountDropdown(
          key: const ValueKey('repayment-source'),
          accounts: assets,
          value: _accountId,
          label: '还款账户',
          onChanged: (value) => setState(() => _accountId = value),
        ),
        const SizedBox(height: 16),
        _accountDropdown(
          key: const ValueKey('repayment-target'),
          accounts: liabilities,
          value: _targetAccountId,
          label: '偿还负债账户',
          onChanged: (value) => setState(() => _targetAccountId = value),
        ),
      ],
    );
  }

  Widget _transferFields(List<LedgerAccount> accounts) {
    final assets = accounts
        .where((item) => item.group == AccountGroup.personalAsset)
        .toList();
    _accountId = assets.any((item) => item.id == _accountId)
        ? _accountId
        : assets.firstOrNull?.id;
    final targets = assets.where((item) => item.id != _accountId).toList();
    _targetAccountId = targets.any((item) => item.id == _targetAccountId)
        ? _targetAccountId
        : targets.firstOrNull?.id;
    return Column(
      children: [
        _accountDropdown(
          key: const ValueKey('transfer-source'),
          accounts: assets,
          value: _accountId,
          label: '转出账户',
          onChanged: (value) => setState(() {
            _accountId = value;
            if (_targetAccountId == value) _targetAccountId = null;
          }),
        ),
        const SizedBox(height: 16),
        _accountDropdown(
          key: ValueKey('transfer-target-$_accountId'),
          accounts: targets,
          value: _targetAccountId,
          label: '转入账户',
          onChanged: (value) => setState(() => _targetAccountId = value),
        ),
      ],
    );
  }

  Widget _accountDropdown({
    required Key key,
    required List<LedgerAccount> accounts,
    required String? value,
    required String label,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      key: key,
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        helperText: accounts.isEmpty ? '请先添加可用账户' : null,
      ),
      items: [
        for (final account in accounts)
          DropdownMenuItem(
            value: account.id,
            child: Text(
              account.kind == AccountKind.creditLine
                  ? '${account.name}（负债）'
                  : account.name,
            ),
          ),
      ],
      onChanged: accounts.isEmpty ? null : onChanged,
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (time == null) return;
    setState(() {
      _occurredAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final accountId = _accountId;
    if (accountId == null ||
        ((_type == LedgerTransactionType.borrowing ||
                _type == LedgerTransactionType.transfer ||
                _type == LedgerTransactionType.repayment) &&
            _targetAccountId == null) ||
        ((_type == LedgerTransactionType.expense ||
                _type == LedgerTransactionType.income) &&
            _categoryId == null)) {
      setState(() => _submissionError = '请先选择所需账户和分类');
      return;
    }

    setState(() {
      _isSaving = true;
      _submissionError = null;
    });
    try {
      final repository = ref.read(expenseRepositoryProvider);
      final record = widget.record;
      if (record == null) {
        await repository.addTransaction(
          type: _type,
          amountMinor: parseCnyMinorUnits(_amountController.text),
          occurredAt: _occurredAt,
          categoryId: _categoryId,
          accountId: accountId,
          targetAccountId: _targetAccountId,
          note: _noteController.text,
        );
      } else {
        await repository.updateTransaction(
          id: record.id,
          type: _type,
          amountMinor: parseCnyMinorUnits(_amountController.text),
          occurredAt: _occurredAt,
          categoryId: _categoryId,
          accountId: accountId,
          targetAccountId: _targetAccountId,
          note: _noteController.text,
        );
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text(_isEditing ? '记录修改已保存' : '记录已保存到本地')),
      );
    } on TransactionRuleException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _submissionError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _submissionError = '保存失败，请稍后重试';
      });
    }
  }
}

String _editableAmount(int minorUnits) {
  final yuan = minorUnits ~/ 100;
  final fen = (minorUnits % 100).toString().padLeft(2, '0');
  return '$yuan.$fen';
}
