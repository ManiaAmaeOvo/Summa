import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/categories/ledger_category.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/expense_repository.dart';
import 'package:summa/features/accounts/account_overview_screen.dart';
import 'package:summa/l10n/default_ledger_labels.dart';
import 'package:summa/l10n/input_error_labels.dart';
import 'package:summa/l10n/l10n.dart';
import 'package:summa/l10n/transaction_rule_labels.dart';

class TransactionEditorSheet extends ConsumerStatefulWidget {
  const TransactionEditorSheet({
    super.key,
    this.record,
    this.refundFor,
    this.refundRemaining = const {},
  });

  final LedgerRecord? record;
  final LedgerRecord? refundFor;
  final Map<String, int> refundRemaining;

  @override
  ConsumerState<TransactionEditorSheet> createState() =>
      _TransactionEditorSheetState();
}

class _TransactionEditorSheetState
    extends ConsumerState<TransactionEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _settlementController = TextEditingController();
  final _quoteController = TextEditingController();
  final _noteController = TextEditingController();
  late LedgerTransactionType _type;
  DateTime _occurredAt = DateTime.now();
  String? _parentCategoryId;
  String? _categoryId;
  String? _accountId;
  String? _targetAccountId;
  String? _submissionError;
  bool _isSaving = false;
  bool _pending = false;
  final _extraPayments = <_SplitPaymentInput>[];
  List<LedgerAccount> _formAccounts = const [];

  String? _accountCurrency(String? id) => _formAccounts
      .where((account) => account.id == id)
      .firstOrNull
      ?.currencyCode;

  String get _sourceCurrency =>
      _accountCurrency(_accountId) ??
      widget.record?.currencyCode ??
      widget.refundFor?.currencyCode ??
      defaultCurrency;

  String? get _settlementCurrency {
    final target = _accountCurrency(_targetAccountId);
    return _type == LedgerTransactionType.transfer && target != _sourceCurrency
        ? target
        : null;
  }

  bool get _isRefund => widget.refundFor != null;
  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _type = record?.type ?? LedgerTransactionType.expense;
    _pending = record?.isPending ?? false;
    if (record == null) {
      final original = widget.refundFor;
      if (original != null && original.occurredAt.isAfter(_occurredAt)) {
        _occurredAt = original.occurredAt;
      }
      return;
    }
    _amountController.text = moneyInputText(
      record.amountMinor,
      record.currencyCode,
    );
    final settlement = record.settlement;
    if (settlement != null) {
      _settlementController.text = moneyInputText(
        settlement.amountMinor,
        settlement.currencyCode,
      );
      _quoteController.text = settlement.quotedRate ?? '';
    }
    _noteController.text = record.note;
    _occurredAt = record.occurredAt;
    _parentCategoryId = record.parentCategoryId;
    _categoryId = record.categoryId;
    _accountId = record.accountId;
    _targetAccountId = record.targetAccountId;
    if (!_isRefund && _type == LedgerTransactionType.expense) {
      for (final leg in record.accountPostings.skip(1)) {
        _extraPayments.add(
          _SplitPaymentInput(leg.accountId, -leg.debitMinor, leg.currencyCode),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _settlementController.dispose();
    _quoteController.dispose();
    _noteController.dispose();
    for (final payment in _extraPayments) {
      payment.amount.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _isRefund
        ? null
        : switch (_type) {
            LedgerTransactionType.expense => ref.watch(
              expenseCategoriesProvider,
            ),
            LedgerTransactionType.income => ref.watch(incomeCategoriesProvider),
            _ => null,
          };
    final accountFields = _isRefund
        ? _refundAccountFields()
        : ref
              .watch(accountsProvider)
              .when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => Text(context.l10n.accountLoadFailed),
                data: _buildAccountFields,
              );
    // The account fields select defaults before amount labels and validators are built.
    final sourceCurrency = _sourceCurrency;
    final settlementCurrency = _settlementCurrency;
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
                    _isRefund
                        ? (_isEditing
                              ? context.l10n.editRefund
                              : context.l10n.recordRefund)
                        : (_isEditing
                              ? context.l10n.editTransaction
                              : context.l10n.addTransaction),
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
              if (!_isRefund)
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
                  suffixText: sourceCurrency,
                  hintText: moneyInputText(0, sourceCurrency),
                ),
                onChanged: settlementCurrency == null
                    ? null
                    : (_) => setState(() {}),
                validator: (value) => _validateAmount(value, sourceCurrency),
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
              accountFields,
              if (settlementCurrency != null)
                _exchangeFields(settlementCurrency),
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
                  hintText: _isRefund ? null : _noteHint(context),
                ),
              ),
              if (!_isEditing)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.saveAsPending),
                  subtitle: _pending
                      ? Text(context.l10n.pendingPostingHint)
                      : null,
                  value: _pending,
                  onChanged: _isSaving
                      ? null
                      : (pending) => setState(() => _pending = pending),
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
      for (final payment in _extraPayments) {
        payment.amount.dispose();
      }
      _extraPayments.clear();
      _settlementController.clear();
      _quoteController.clear();
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
    _formAccounts = selectable;
    return switch (_type) {
      LedgerTransactionType.expense => _expenseFields(selectable),
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
          currencyCode: record.currencyCode,
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
          currencyCode:
              record.accountPostings
                  .where((leg) => leg.accountId == record.targetAccountId)
                  .firstOrNull
                  ?.currencyCode ??
              record.currencyCode,
        ),
      );
    }
    for (final leg in record.accountPostings.skip(1)) {
      if (!result.any((item) => item.id == leg.accountId)) {
        result.add(
          LedgerAccount(
            id: leg.accountId,
            name: context.l10n.archivedName(leg.accountName),
            kind: AccountKind.values.byName(leg.accountKind),
            currencyCode: leg.currencyCode,
          ),
        );
      }
    }
    return result;
  }

  Widget _expenseFields(List<LedgerAccount> accounts) {
    final extraIds = _extraPayments.map((leg) => leg.accountId).toSet();
    final unused = accounts.where(
      (account) =>
          account.id != _accountId &&
          !extraIds.contains(account.id) &&
          account.currencyCode == _sourceCurrency,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _singleAccountField(
          accounts
              .where(
                (account) =>
                    !extraIds.contains(account.id) &&
                    (extraIds.isEmpty ||
                        account.currencyCode == _sourceCurrency),
              )
              .toList(),
          label: context.l10n.paymentAccount,
        ),
        if (_extraPayments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(context.l10n.mainPaymentRemainder),
          ),
        for (final payment in _extraPayments)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              key: ObjectKey(payment),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _accountDropdown(
                        key: ObjectKey(payment.amount),
                        accounts: accounts
                            .where(
                              (account) =>
                                  account.id == payment.accountId ||
                                  (account.id != _accountId &&
                                      !extraIds.contains(account.id) &&
                                      account.currencyCode == _sourceCurrency),
                            )
                            .toList(),
                        value: payment.accountId,
                        label: context.l10n.paymentAccount,
                        onChanged: (id) {
                          if (id != null) {
                            setState(() => payment.accountId = id);
                          }
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              setState(() => _extraPayments.remove(payment));
                              // The field detaches from the controller on the next build.
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => payment.amount.dispose(),
                              );
                            },
                      tooltip: context.l10n.removePaymentAccount,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: payment.amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: context.l10n.extraPaymentAmount,
                    suffixText: _sourceCurrency,
                  ),
                  validator: (value) => _validateAmount(value, _sourceCurrency),
                ),
              ],
            ),
          ),
        if (unused.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _isSaving
                  ? null
                  : () => setState(() {
                      _extraPayments.add(
                        _SplitPaymentInput(unused.first.id, 0, _sourceCurrency),
                      );
                    }),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.addPaymentAccount),
            ),
          ),
      ],
    );
  }

  Widget _refundAccountFields() {
    final accounts = [
      for (final leg in widget.refundFor!.accountPostings)
        if ((widget.refundRemaining[leg.accountId] ?? 0) > 0)
          LedgerAccount(
            id: leg.accountId,
            name: leg.accountName,
            kind: AccountKind.values.byName(leg.accountKind),
            currencyCode: leg.currencyCode,
          ),
    ];
    _formAccounts = accounts;
    final dropdown = _singleAccountField(
      accounts,
      label: context.l10n.incomeDestinationAccount,
    );
    final maximum = widget.refundRemaining[_accountId] ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        dropdown,
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            context.l10n.refundAvailable(formatMoney(maximum, _sourceCurrency)),
          ),
        ),
      ],
    );
  }

  String? _validateAmount(String? value, String currency) {
    try {
      parseMoney(value ?? '', currency);
      return null;
    } on MoneyInputException catch (error) {
      return localizedMoneyInputError(context, error, currency: currency);
    }
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
    _accountId = liabilities.any((item) => item.id == _accountId)
        ? _accountId
        : liabilities.firstOrNull?.id;
    final assets = accounts
        .where(
          (item) =>
              item.group == AccountGroup.personalAsset &&
              item.currencyCode == _sourceCurrency,
        )
        .toList();
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
          key: ValueKey('borrowing-target-$_accountId'),
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
    _accountId = assets.any((item) => item.id == _accountId)
        ? _accountId
        : assets.firstOrNull?.id;
    final liabilities = accounts
        .where(
          (item) =>
              item.group == AccountGroup.liability &&
              item.currencyCode == _sourceCurrency,
        )
        .toList();
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
          key: ValueKey('repayment-target-$_accountId'),
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
            _settlementController.clear();
            _quoteController.clear();
            if (_targetAccountId == value) _targetAccountId = null;
          }),
        ),
        const SizedBox(height: 16),
        _accountDropdown(
          key: ValueKey('transfer-target-$_accountId'),
          accounts: targets,
          value: _targetAccountId,
          label: context.l10n.transferToAccount,
          onChanged: (value) => setState(() {
            _targetAccountId = value;
            _settlementController.clear();
            _quoteController.clear();
          }),
        ),
      ],
    );
  }

  Widget _exchangeFields(String targetCurrency) {
    final sourceCurrency = _sourceCurrency;
    String? effective;
    try {
      effective = effectiveExchangeRate(
        sourceMinor: parseMoney(_amountController.text, sourceCurrency),
        sourceCurrency: sourceCurrency,
        settlementMinor: parseMoney(_settlementController.text, targetCurrency),
        settlementCurrency: targetCurrency,
      );
    } on MoneyInputException {
      // The preview becomes available once both amounts are valid.
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('transfer-settlement-amount'),
          controller: _settlementController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: context.l10n.transferSettlementAmount,
            suffixText: targetCurrency,
          ),
          onChanged: (_) => setState(() {}),
          validator: (value) => _validateAmount(value, targetCurrency),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const ValueKey('transfer-exchange-quote'),
          controller: _quoteController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: context.l10n.quotedExchangeRate,
            helperText: context.l10n.exchangeRateDirection(
              targetCurrency,
              sourceCurrency,
            ),
          ),
          validator: (value) {
            final quote = value?.trim() ?? '';
            return quote.isEmpty || isValidExchangeQuote(quote)
                ? null
                : context.l10n.invalidQuotedExchangeRate;
          },
        ),
        if (effective != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              context.l10n.effectiveExchangeRateLabel(
                sourceCurrency,
                effective,
                targetCurrency,
              ),
            ),
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
              _accountOption(account),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      isExpanded: true,
      onChanged: accounts.isEmpty || _isSaving ? null : onChanged,
    );
  }

  String _accountOption(LedgerAccount account) {
    final name = DefaultLedgerLabels.account(context, account);
    final withKind = account.kind == AccountKind.creditLine
        ? context.l10n.liabilityName(name)
        : name;
    return account.currencyCode == defaultCurrency
        ? withKind
        : '$withKind · ${account.currencyCode}';
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: widget.refundFor?.occurredAt ?? DateTime(2000),
      lastDate: _occurredAt.isAfter(DateTime.now())
          ? _occurredAt.add(const Duration(days: 1))
          : DateTime.now().add(const Duration(days: 1)),
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
        (!_isRefund &&
            (_type == LedgerTransactionType.expense ||
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
      final amount = parseMoney(_amountController.text, _sourceCurrency);
      final targetCurrency = _settlementCurrency;
      final quote = _quoteController.text.trim();
      final settlement = targetCurrency == null
          ? null
          : TransferSettlement(
              amountMinor: parseMoney(
                _settlementController.text,
                targetCurrency,
              ),
              currencyCode: targetCurrency,
              quotedRate: quote.isEmpty ? null : quote,
            );
      final status = _pending
          ? LedgerPostingStatus.pending
          : LedgerPostingStatus.posted;
      List<AccountPayment>? payments;
      if (!_isRefund && _type == LedgerTransactionType.expense) {
        final rest = [
          for (final input in _extraPayments)
            AccountPayment(
              input.accountId,
              parseMoney(input.amount.text, _sourceCurrency),
            ),
        ];
        final primary = rest.fold(
          amount,
          (remaining, item) =>
              remaining > item.amountMinor ? remaining - item.amountMinor : 0,
        );
        if (primary <= 0) {
          throw const TransactionRuleException(
            TransactionRuleError.invalidPaymentSplit,
          );
        }
        payments = [AccountPayment(accountId, primary), ...rest];
      }
      if (_isRefund) {
        await repository.saveRefund(
          id: record?.id,
          originalId: widget.refundFor!.id,
          accountId: accountId,
          amountMinor: amount,
          occurredAt: _occurredAt,
          note: _noteController.text,
          status: status,
        );
      } else if (record == null) {
        await repository.addTransaction(
          type: _type,
          amountMinor: amount,
          occurredAt: _occurredAt,
          categoryId: _categoryId,
          accountId: accountId,
          targetAccountId: _targetAccountId,
          payments: payments,
          settlement: settlement,
          status: status,
          note: _noteController.text,
        );
      } else {
        await repository.updateTransaction(
          id: record.id,
          type: _type,
          amountMinor: amount,
          occurredAt: _occurredAt,
          categoryId: _categoryId,
          accountId: accountId,
          targetAccountId: _targetAccountId,
          payments: payments,
          settlement: settlement,
          note: _noteController.text,
        );
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isRefund
                ? context.l10n.refundRecorded
                : _isEditing
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

class _SplitPaymentInput {
  _SplitPaymentInput(this.accountId, int minor, String currency)
    : amount = TextEditingController(
        text: minor == 0 ? '' : moneyInputText(minor, currency),
      );

  String accountId;
  final TextEditingController amount;
}
