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
import 'package:ledger_pro/l10n/default_ledger_labels.dart';
import 'package:ledger_pro/l10n/input_error_labels.dart';
import 'package:ledger_pro/l10n/l10n.dart';
import 'package:ledger_pro/l10n/transaction_rule_labels.dart';

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
                    _isEditing
                        ? context.l10n.editTransaction
                        : context.l10n.addTransaction,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: context.l10n.close,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<LedgerTransactionType>(
                  segments: [
                    ButtonSegment(
                      value: LedgerTransactionType.expense,
                      label: Text(context.l10n.expense),
                    ),
                    ButtonSegment(
                      value: LedgerTransactionType.income,
                      label: Text(context.l10n.income),
                    ),
                    ButtonSegment(
                      value: LedgerTransactionType.transfer,
                      label: Text(context.l10n.transfer),
                    ),
                    ButtonSegment(
                      value: LedgerTransactionType.borrowing,
                      label: Text(context.l10n.borrowing),
                    ),
                    ButtonSegment(
                      value: LedgerTransactionType.repayment,
                      label: Text(context.l10n.repayment),
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
                decoration: InputDecoration(
                  labelText: context.l10n.amount,
                  prefixText: '¥ ',
                  hintText: '0.00',
                ),
                validator: (value) {
                  try {
                    parseCnyMinorUnits(value ?? '');
                    return null;
                  } on MoneyInputException catch (error) {
                    return localizedMoneyInputError(context, error);
                  }
                },
              ),
              if (categories != null) ...[
                const SizedBox(height: 16),
                categories.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => Text(context.l10n.categoryLoadFailed),
                  data: _buildCategoryFields,
                ),
              ],
              const SizedBox(height: 16),
              accounts.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => Text(context.l10n.accountLoadFailed),
                data: _buildAccountFields,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickDateTime,
                icon: const Icon(Icons.schedule),
                label: Text(
                  DateFormat.yMMMd(
                    Localizations.localeOf(context).toLanguageTag(),
                  ).add_Hm().format(_occurredAt),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: context.l10n.noteOptional,
                  hintText: _noteHint(context),
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
                label: Text(
                  _isEditing
                      ? context.l10n.saveChanges
                      : context.l10n.saveTransaction,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _noteHint(BuildContext context) => switch (_type) {
    LedgerTransactionType.expense => context.l10n.expenseNoteHint,
    LedgerTransactionType.income => context.l10n.incomeNoteHint,
    LedgerTransactionType.transfer => context.l10n.transferNoteHint,
    LedgerTransactionType.borrowing => context.l10n.borrowingNoteHint,
    LedgerTransactionType.repayment => context.l10n.repaymentNoteHint,
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
            decoration: InputDecoration(
              labelText: context.l10n.primaryCategory,
            ),
            items: [
              for (final parent in parents)
                DropdownMenuItem(
                  value: parent.id,
                  child: Text(DefaultLedgerLabels.category(context, parent)),
                ),
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
            decoration: InputDecoration(
              labelText: context.l10n.secondaryCategory,
            ),
            items: [
              for (final child in children)
                DropdownMenuItem(
                  value: child.id,
                  child: Text(DefaultLedgerLabels.category(context, child)),
                ),
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
        label: context.l10n.paymentAccount,
      ),
      LedgerTransactionType.income => _singleAccountField(
        selectable,
        label: context.l10n.incomeDestinationAccount,
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
          name: context.l10n.archivedName(record.accountName),
          kind: AccountKind.values.byName(record.accountKind),
        ),
      );
    }
    if (record.targetAccountId != null &&
        !result.any((item) => item.id == record.targetAccountId)) {
      result.add(
        LedgerAccount(
          id: record.targetAccountId!,
          name: context.l10n.archivedName(record.targetAccountName!),
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
          label: context.l10n.liabilityAccounts,
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
            label: Text(context.l10n.quickAddLiability),
          ),
        ),
        const SizedBox(height: 4),
        _accountDropdown(
          key: const ValueKey('borrowing-target'),
          accounts: assets,
          value: _targetAccountId,
          label: context.l10n.fundsDestinationAccount,
          onChanged: (value) => setState(() => _targetAccountId = value),
        ),
      ],
    );
  }

  Widget _repaymentFields(List<LedgerAccount> accounts) {
    final assets = accounts
        .where((item) => item.group != AccountGroup.liability)
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
          label: context.l10n.repaymentSourceAccount,
          onChanged: (value) => setState(() => _accountId = value),
        ),
        const SizedBox(height: 16),
        _accountDropdown(
          key: const ValueKey('repayment-target'),
          accounts: liabilities,
          value: _targetAccountId,
          label: context.l10n.repaymentLiabilityAccount,
          onChanged: (value) => setState(() => _targetAccountId = value),
        ),
      ],
    );
  }

  Widget _transferFields(List<LedgerAccount> accounts) {
    final assets = accounts
        .where((item) => item.group != AccountGroup.liability)
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
          label: context.l10n.transferFromAccount,
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
          label: context.l10n.transferToAccount,
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
        helperText: accounts.isEmpty
            ? context.l10n.addAvailableAccountFirst
            : null,
      ),
      items: [
        for (final account in accounts)
          DropdownMenuItem(
            value: account.id,
            child: Text(
              account.kind == AccountKind.creditLine
                  ? context.l10n.liabilityName(
                      DefaultLedgerLabels.account(context, account),
                    )
                  : DefaultLedgerLabels.account(context, account),
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
      setState(
        () => _submissionError = context.l10n.selectRequiredAccountAndCategory,
      );
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
        SnackBar(
          content: Text(
            _isEditing
                ? context.l10n.transactionChangesSaved
                : context.l10n.transactionSavedLocally,
          ),
        ),
      );
    } on TransactionRuleException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _submissionError = localizedTransactionRule(context, error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _submissionError = context.l10n.saveLaterFailed;
      });
    }
  }
}

String _editableAmount(int minorUnits) {
  final yuan = minorUnits ~/ 100;
  final fen = (minorUnits % 100).toString().padLeft(2, '0');
  return '$yuan.$fen';
}
