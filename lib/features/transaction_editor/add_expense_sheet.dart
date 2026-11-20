import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/app/widgets/currency_selector.dart';
import 'package:summa/app/widgets/ledger_surfaces.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/categories/ledger_category.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/expense_repository.dart';
import 'package:summa/domain/transactions/transaction_terms.dart';
import 'package:summa/features/accounts/account_overview_screen.dart';
import 'package:summa/features/transaction_editor/payment_notice_dialog.dart';
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
  final _originalAmount = TextEditingController();
  final _purchaseQuote = TextEditingController();
  final _advanceAmount = TextEditingController();
  final _feeAmount = TextEditingController();
  final _interestAmount = TextEditingController();
  final _categoryShares = <_SplitCategoryInput>[];
  String? _originalCurrency;
  String? _advanceAccountId;
  bool _foreignPurchase = false;
  bool _includeAdvance = false;
  bool _externalDebtPayment = false;
  late LedgerTransactionType _type;
  DateTime _occurredAt = DateTime.now();
  String? _parentCategoryId;
  String? _categoryId;
  String? _accountId;
  String? _targetAccountId;
  String? _submissionError;
  bool _isSaving = false;
  bool _pending = false;
  bool _reviewingPaymentNotice = false;
  bool _familyFunded = false;
  String _familyCurrency = defaultCurrency;
  final _extraPayments = <_SplitPaymentInput>[];
  List<LedgerAccount> _formAccounts = const [];

  String? _accountCurrency(String? id) => _formAccounts
      .where((account) => account.id == id)
      .firstOrNull
      ?.currencyCode;

  String get _sourceCurrency => _familyFunded
      ? _familyCurrency
      : _accountCurrency(_accountId) ??
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

  Future<void> _pastePaymentNotice() async {
    FocusScope.of(context).unfocus();
    final result = await showDialog<ReviewedPaymentNotice>(
      context: context,
      builder: (_) => const PaymentNoticeDialog(),
    );
    if (!mounted || result == null) return;
    _changeType(result.draft.type);
    setState(() {
      _reviewingPaymentNotice = true;
      _pending = true;
      _accountId = result.accountId;
      _amountController.text = moneyInputText(
        result.draft.amountMinor,
        defaultCurrency,
      );
      _noteController.text = result.draft.note;
    });
  }

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _type = record?.type ?? LedgerTransactionType.expense;
    _pending = record?.isPending ?? false;
    _familyFunded = !_isRefund && (record?.isFamilyDirect ?? false);
    _familyCurrency = record?.currencyCode ?? defaultCurrency;
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
    if (_isRefund && record.terms.advance != null) {
      _advanceAmount.text = moneyInputText(
        record.terms.advance!.amountMinor,
        record.currencyCode,
      );
    }
    if (!_isRefund) {
      final terms = record.terms;
      if (terms.originalPrice case final price?) {
        _foreignPurchase = true;
        _originalCurrency = price.currencyCode;
        _originalAmount.text = moneyInputText(
          price.amountMinor,
          price.currencyCode,
        );
        _purchaseQuote.text = price.quotedRate ?? '';
      }
      if (terms.advance case final advance?) {
        _includeAdvance = true;
        _advanceAccountId = advance.accountId;
        _advanceAmount.text = moneyInputText(
          advance.amountMinor,
          record.currencyCode,
        );
      }
      for (final part in terms.categories.skip(1)) {
        _categoryShares.add(
          _SplitCategoryInput(
            part.categoryId,
            moneyInputText(part.amountMinor, record.currencyCode),
          ),
        );
      }
      if (terms.feeMinor > 0) {
        _feeAmount.text = moneyInputText(terms.feeMinor, record.currencyCode);
      }
      if (terms.interestMinor > 0) {
        _interestAmount.text = moneyInputText(
          terms.interestMinor,
          record.currencyCode,
        );
      }
      _externalDebtPayment = terms.externalDebtPayment;
    }
    if (!_isRefund &&
        !_familyFunded &&
        _type == LedgerTransactionType.expense) {
      for (final leg
          in record.accountPostings
              .skip(1)
              .where((leg) => leg.debitMinor < 0)) {
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
    _originalAmount.dispose();
    _purchaseQuote.dispose();
    _advanceAmount.dispose();
    _feeAmount.dispose();
    _interestAmount.dispose();
    for (final share in _categoryShares) {
      share.amount.dispose();
    }
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
        : _familyFunded
        ? CurrencySelector(
            currencies: currencyOptions(currencyMinorDigits.keys),
            value: _familyCurrency,
            label: context.l10n.currencyLabel,
            onChanged: _isEditing || _isSaving
                ? null
                : (code) => setState(() => _familyCurrency = code),
          )
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
                  Expanded(
                    child: Text(
                      _isRefund
                          ? (_isEditing
                                ? context.l10n.editRefund
                                : context.l10n.recordRefund)
                          : (_isEditing
                                ? context.l10n.editTransaction
                                : context.l10n.addTransaction),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  if (!_isEditing && !_isRefund)
                    IconButton(
                      onPressed: _isSaving ? null : _pastePaymentNotice,
                      icon: const Icon(Icons.content_paste_search_outlined),
                      tooltip: context.l10n.pastePaymentNotice,
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: context.l10n.close,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!_isRefund)
                LedgerChoiceBar<LedgerTransactionType>(
                  options: {
                    LedgerTransactionType.expense: context.l10n.expense,
                    LedgerTransactionType.income: context.l10n.income,
                    LedgerTransactionType.transfer: context.l10n.transfer,
                    LedgerTransactionType.borrowing: context.l10n.borrowing,
                    LedgerTransactionType.repayment: context.l10n.repayment,
                    LedgerTransactionType.lending: context.l10n.lending,
                    LedgerTransactionType.advance: context.l10n.advance,
                    LedgerTransactionType.collection: context.l10n.collection,
                    LedgerTransactionType.reimbursement:
                        context.l10n.reimbursement,
                  },
                  selected: _type,
                  onChanged: _isSaving ? null : _changeType,
                ),
              const SizedBox(height: 16),
              if (_reviewingPaymentNotice) ...[
                Text(context.l10n.paymentNoticeCheck),
                const SizedBox(height: 8),
              ],
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
                  labelText: !_isRefund && _foreignPurchase
                      ? context.l10n.settledPurchaseAmount
                      : context.l10n.amount,
                  suffixText: sourceCurrency,
                  hintText: moneyInputText(0, sourceCurrency),
                ),
                onChanged: settlementCurrency == null
                    ? null
                    : (_) => setState(() {}),
                validator: (value) => _validateAmount(value, sourceCurrency),
              ),
              if (widget.record?.needsReview == true)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(context.l10n.fundingReviewHint),
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
              if (!_isRefund && _type == LedgerTransactionType.expense)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.familyDirectFunding),
                  subtitle: _familyFunded
                      ? Text(context.l10n.familyDirectExplanation)
                      : null,
                  value: _familyFunded,
                  onChanged: _isSaving ? null : _setFamilyFunding,
                ),
              accountFields,
              if (widget.refundFor?.terms.advance != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextFormField(
                    controller: _advanceAmount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: context.l10n.refundAdvanceShare,
                      helperText: context.l10n.refundAdvanceHint,
                      helperMaxLines: 2,
                      suffixText: sourceCurrency,
                    ),
                  ),
                ),
              if (!_isRefund && _type == LedgerTransactionType.expense)
                _purchaseDetails(categories?.asData?.value ?? const []),
              if (!_isRefund &&
                  (_type == LedgerTransactionType.transfer ||
                      _type == LedgerTransactionType.repayment) &&
                  !_externalDebtPayment)
                _chargeFields(),
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

  String? _noteHint(BuildContext context) => switch (_type) {
    LedgerTransactionType.expense => context.l10n.expenseNoteHint,
    LedgerTransactionType.income => context.l10n.incomeNoteHint,
    LedgerTransactionType.transfer => context.l10n.transferNoteHint,
    LedgerTransactionType.borrowing => context.l10n.borrowingNoteHint,
    LedgerTransactionType.repayment => context.l10n.repaymentNoteHint,
    _ => null,
  };

  void _setFamilyFunding(bool selected) {
    final currency = _sourceCurrency;
    setState(() {
      _familyFunded = selected;
      if (selected) {
        _includeAdvance = false;
        _foreignPurchase = false;
      }
      _familyCurrency = currency;
      _accountId = null;
      _targetAccountId = null;
      _submissionError = null;
      final removed = List.of(_extraPayments);
      _extraPayments.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final payment in removed) {
          payment.amount.dispose();
        }
      });
    });
  }

  void _changeType(LedgerTransactionType value) {
    setState(() {
      for (final payment in _extraPayments) {
        payment.amount.dispose();
      }
      _extraPayments.clear();
      _settlementController.clear();
      _quoteController.clear();
      final oldShares = List.of(_categoryShares);
      _categoryShares.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final share in oldShares) {
          share.amount.dispose();
        }
      });
      _originalAmount.clear();
      _purchaseQuote.clear();
      _advanceAmount.clear();
      _feeAmount.clear();
      _interestAmount.clear();
      _foreignPurchase = false;
      _includeAdvance = false;
      _externalDebtPayment = false;
      _type = value;
      _reviewingPaymentNotice = false;
      _familyFunded = false;
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

    final primary = DropdownButtonFormField<String>(
      key: ValueKey('parent-${_type.name}'),
      initialValue: parentId,
      isExpanded: true,
      decoration: InputDecoration(labelText: context.l10n.primaryCategory),
      items: _categoryOptions(parents),
      onChanged: (value) => setState(() {
        _parentCategoryId = value;
        _categoryId = null;
      }),
    );
    final secondary = DropdownButtonFormField<String>(
      key: ValueKey('$parentId-${_type.name}'),
      initialValue: categoryId,
      isExpanded: true,
      decoration: InputDecoration(labelText: context.l10n.secondaryCategory),
      items: _categoryOptions(children),
      onChanged: (value) => setState(() => _categoryId = value),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final minFieldWidth = MediaQuery.textScalerOf(context).scale(16) * 10;
        if (constraints.maxWidth < 2 * minFieldWidth + 12) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [primary, const SizedBox(height: 12), secondary],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: primary),
            const SizedBox(width: 12),
            Expanded(child: secondary),
          ],
        );
      },
    );
  }

  List<DropdownMenuItem<String>> _categoryOptions(
    List<LedgerCategory> categories,
  ) => [
    for (final category in categories)
      DropdownMenuItem(
        value: category.id,
        child: Text(
          DefaultLedgerLabels.category(context, category),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
  ];

  Widget _buildAccountFields(List<LedgerAccount> accounts) {
    final selectable = _reviewingPaymentNotice
        ? accounts
              .where((account) => account.currencyCode == defaultCurrency)
              .toList()
        : _withOriginalArchivedAccounts(accounts);
    _formAccounts = selectable;
    return switch (_type) {
      LedgerTransactionType.expense => _expenseFields(
        selectable
            .where((account) => account.kind != AccountKind.receivable)
            .toList(),
      ),
      LedgerTransactionType.income => _singleAccountField(
        selectable
            .where(
              (account) =>
                  account.kind != AccountKind.receivable &&
                  account.kind != AccountKind.thirdPartyPayable,
            )
            .toList(),
        label: context.l10n.incomeDestinationAccount,
      ),
      LedgerTransactionType.adjustment => const SizedBox.shrink(),
      LedgerTransactionType.borrowing => _borrowingFields(selectable),
      LedgerTransactionType.repayment => _repaymentFields(selectable),
      LedgerTransactionType.transfer => _transferFields(selectable),
      LedgerTransactionType.lending ||
      LedgerTransactionType.advance ||
      LedgerTransactionType.collection ||
      LedgerTransactionType.reimbursement => _receivableFields(selectable),
    };
  }

  List<LedgerAccount> _withOriginalArchivedAccounts(
    List<LedgerAccount> accounts,
  ) {
    final result = [...accounts];
    final record = widget.record;
    if (record == null) return result;
    if (!record.isFamilyDirect &&
        !result.any((item) => item.id == record.accountId)) {
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

  Widget _purchaseDetails(List<LedgerCategory> categories) {
    final labels = context.l10n;
    final currency = _sourceCurrency;
    final children = {
      for (final category in categories)
        if (!category.isParent && category.id != _categoryId)
          category.id: DefaultLedgerLabels.category(context, category),
      for (final share in _categoryShares)
        if (!categories.any((category) => category.id == share.categoryId))
          share.categoryId:
              widget.record?.allocationLabels[share.categoryId]?.name ??
              share.categoryId,
    };
    final receivables = _formAccounts
        .where(
          (account) =>
              account.kind == AccountKind.receivable &&
              account.currencyCode == currency,
        )
        .toList();
    final originalCurrencies = currencyOptions(currencyMinorDigits.keys)
        .where((code) => code != currency)
        .toList();
    if (_foreignPurchase && !originalCurrencies.contains(_originalCurrency)) {
      _originalCurrency = originalCurrencies.firstOrNull;
    }
    if (_includeAdvance &&
        !receivables.any((account) => account.id == _advanceAccountId)) {
      _advanceAccountId = receivables.firstOrNull?.id;
    }
    return ExpansionTile(
      key: const ValueKey('purchase-details'),
      initiallyExpanded:
          _foreignPurchase || _includeAdvance || _categoryShares.isNotEmpty,
      maintainState: true,
      tilePadding: EdgeInsets.zero,
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      title: Text(labels.transactionDetails),
      children: [
        if (!_familyFunded) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(labels.foreignPurchase),
            value: _foreignPurchase,
            onChanged: (value) => setState(() => _foreignPurchase = value),
          ),
          if (_foreignPurchase && _originalCurrency != null) ...[
            CurrencySelector(
              currencies: originalCurrencies,
              value: _originalCurrency!,
              label: labels.originalCurrency,
              onChanged: (currency) =>
                  setState(() => _originalCurrency = currency),
            ),
            _detailAmount(
              _originalAmount,
              labels.originalPrice,
              _originalCurrency!,
            ),
            TextFormField(
              controller: _purchaseQuote,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: labels.quotedExchangeRate,
                helperText: labels.exchangeRateDirection(
                  currency,
                  _originalCurrency!,
                ),
              ),
              validator: (value) {
                final quote = value?.trim() ?? '';
                return quote.isEmpty || isValidExchangeQuote(quote)
                    ? null
                    : labels.invalidQuotedExchangeRate;
              },
            ),
          ],
          if (_accountIsPersonalCash)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(labels.advanceForOthers),
              value: _includeAdvance,
              onChanged: (value) => setState(() => _includeAdvance = value),
            ),
          if (_includeAdvance) ...[
            _accountDropdown(
              key: ValueKey('bill-receivable-$currency'),
              accounts: receivables,
              value: _advanceAccountId,
              label: labels.receivableAccount,
              onChanged: (id) => setState(() => _advanceAccountId = id),
            ),
            if (receivables.isEmpty)
              TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AddAccountDialog(
                    initialKind: AccountKind.receivable,
                    initialCurrency: currency,
                  ),
                ),
                child: Text(labels.quickAddReceivable),
              ),
            _detailAmount(_advanceAmount, labels.advanceShare, currency),
          ],
        ],
        for (final share in _categoryShares)
          Padding(
            key: ObjectKey(share),
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: children.containsKey(share.categoryId)
                            ? share.categoryId
                            : null,
                        decoration: InputDecoration(
                          labelText: labels.additionalCategory,
                        ),
                        items: [
                          for (final item in children.entries)
                            DropdownMenuItem(
                              value: item.key,
                              child: Text(
                                item.value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (id) => setState(() {
                          if (id != null) share.categoryId = id;
                        }),
                      ),
                    ),
                    IconButton(
                      tooltip: labels.delete,
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        setState(() => _categoryShares.remove(share));
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => share.amount.dispose(),
                        );
                      },
                    ),
                  ],
                ),
                _detailAmount(share.amount, labels.categoryShare, currency),
              ],
            ),
          ),
        if (children.keys
                .where(
                  (id) =>
                      !_categoryShares.any((share) => share.categoryId == id),
                )
                .firstOrNull
            case final available?)
          TextButton.icon(
            onPressed: () => setState(
              () => _categoryShares.add(_SplitCategoryInput(available, '')),
            ),
            icon: const Icon(Icons.add),
            label: Text(labels.splitCategories),
          ),
      ],
    );
  }

  bool get _accountIsPersonalCash => _formAccounts.any(
    (account) => account.id == _accountId && account.kind.isPersonalCash,
  );

  Widget _chargeFields() => ExpansionTile(
    key: ValueKey('charges-${_type.name}'),
    initiallyExpanded:
        _feeAmount.text.isNotEmpty || _interestAmount.text.isNotEmpty,
    maintainState: true,
    tilePadding: EdgeInsets.zero,
    title: Text(context.l10n.transactionDetails),
    children: [
      _detailAmount(
        _feeAmount,
        context.l10n.feeAmount,
        _sourceCurrency,
        optional: true,
      ),
      if (_type == LedgerTransactionType.repayment)
        _detailAmount(
          _interestAmount,
          context.l10n.interestAmount,
          _sourceCurrency,
          optional: true,
        ),
    ],
  );

  Widget _detailAmount(
    TextEditingController controller,
    String label,
    String currency, {
    bool optional = false,
  }) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, suffixText: currency),
      validator: (value) => optional && (value?.trim().isEmpty ?? true)
          ? null
          : _validateAmount(value, currency),
    ),
  );

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
    final thirdPartyOption = SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(context.l10n.externalDebtPayment),
      subtitle: _externalDebtPayment
          ? Text(context.l10n.externalDebtPaymentHint)
          : null,
      value: _externalDebtPayment,
      onChanged: _isSaving
          ? null
          : (value) => setState(() {
              _externalDebtPayment = value;
              _accountId = value ? _targetAccountId : null;
              _targetAccountId = null;
            }),
    );
    if (_externalDebtPayment) {
      return Column(
        children: [
          thirdPartyOption,
          _singleAccountField(
            accounts.where((item) => item.kind.isLiability).toList(),
            label: context.l10n.repaymentLiabilityAccount,
          ),
        ],
      );
    }
    final assets = accounts
        .where(
          (item) =>
              item.kind.isPersonalCash ||
              item.kind == AccountKind.entrustedFunds,
        )
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
        thirdPartyOption,
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

  Widget _receivableFields(List<LedgerAccount> accounts) {
    final opening = _type.originatesReceivable;
    bool isReceivable(LedgerAccount account) =>
        account.kind == AccountKind.receivable;
    final sources = accounts
        .where(
          (account) =>
              opening ? account.kind.isPersonalCash : isReceivable(account),
        )
        .toList();
    _accountId = sources.any((item) => item.id == _accountId)
        ? _accountId
        : sources.firstOrNull?.id;
    final targets = accounts
        .where(
          (account) =>
              (opening ? isReceivable(account) : account.kind.isPersonalCash) &&
              account.currencyCode == _sourceCurrency,
        )
        .toList();
    _targetAccountId = targets.any((item) => item.id == _targetAccountId)
        ? _targetAccountId
        : targets.firstOrNull?.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_type == LedgerTransactionType.advance) ...[
          Text(context.l10n.advanceEditorHint),
          const SizedBox(height: 12),
        ],
        _accountDropdown(
          key: ValueKey('${_type.name}-source'),
          accounts: sources,
          value: _accountId,
          label: opening
              ? context.l10n.transferFromAccount
              : context.l10n.receivableAccount,
          onChanged: (value) => setState(() => _accountId = value),
        ),
        const SizedBox(height: 12),
        _accountDropdown(
          key: ValueKey('${_type.name}-target-$_accountId'),
          accounts: targets,
          value: _targetAccountId,
          label: opening
              ? context.l10n.receivableAccount
              : context.l10n.incomeDestinationAccount,
          onChanged: (value) => setState(() => _targetAccountId = value),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: _isSaving
                ? null
                : () => showDialog<void>(
                    context: context,
                    builder: (_) => AddAccountDialog(
                      initialKind: AccountKind.receivable,
                      initialCurrency: _sourceCurrency,
                    ),
                  ),
            icon: const Icon(Icons.add),
            label: Text(context.l10n.quickAddReceivable),
          ),
        ),
      ],
    );
  }

  Widget _transferFields(List<LedgerAccount> accounts) {
    final assets = accounts
        .where(
          (item) =>
              item.kind.isPersonalCash ||
              item.kind == AccountKind.entrustedFunds ||
              item.kind == AccountKind.prepaid,
        )
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
    final withKind = switch (account.kind) {
      AccountKind.familyDirect => context.l10n.familyDirectFunding,
      AccountKind.savings => context.l10n.accountKindSavings,
      AccountKind.prepaid => context.l10n.accountKindPrepaid,
      AccountKind.creditLine => context.l10n.liabilityName(name),
      AccountKind.thirdPartyPayable =>
        '$name · ${context.l10n.accountKindThirdPartyPayable}',
      AccountKind.receivable => '$name · ${context.l10n.accountKindReceivable}',
      _ => name,
    };
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

  TransactionTerms _buildTerms(int amount) {
    final currency = _sourceCurrency;
    int optional(TextEditingController controller) =>
        controller.text.trim().isEmpty
        ? 0
        : parseMoney(controller.text, currency);
    if (_type == LedgerTransactionType.transfer ||
        _type == LedgerTransactionType.repayment) {
      return _externalDebtPayment
          ? const TransactionTerms(externalDebtPayment: true)
          : TransactionTerms(
              feeMinor: optional(_feeAmount),
              interestMinor: _type == LedgerTransactionType.repayment
                  ? optional(_interestAmount)
                  : 0,
            );
    }
    if (_type != LedgerTransactionType.expense) return const TransactionTerms();
    final AccountPayment? advance;
    if (_includeAdvance) {
      if (_advanceAccountId == null || !_accountIsPersonalCash) {
        throw const TransactionRuleException(
          TransactionRuleError.invalidTransactionDetails,
        );
      }
      advance = AccountPayment(
        _advanceAccountId!,
        parseMoney(_advanceAmount.text, currency),
      );
    } else {
      advance = null;
    }
    final shares = [
      for (final part in _categoryShares)
        (
          categoryId: part.categoryId,
          amountMinor: parseMoney(part.amount.text, currency),
        ),
    ];
    var primary = amount - (advance?.amountMinor ?? 0);
    for (final share in shares) {
      if (primary <= share.amountMinor) {
        throw const TransactionRuleException(
          TransactionRuleError.invalidTransactionDetails,
        );
      }
      primary -= share.amountMinor;
    }
    return TransactionTerms(
      originalPrice: _foreignPurchase
          ? TransferSettlement(
              amountMinor: parseMoney(_originalAmount.text, _originalCurrency!),
              currencyCode: _originalCurrency!,
              quotedRate: _purchaseQuote.text.trim().isEmpty
                  ? null
                  : _purchaseQuote.text.trim(),
            )
          : null,
      advance: advance,
      categories: shares.isEmpty
          ? const []
          : [(categoryId: _categoryId!, amountMinor: primary), ...shares],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _submissionError = context.l10n.invalidTransactionDetails);
      return;
    }
    final accountId = _accountId;
    if ((!_familyFunded && accountId == null) ||
        ((_type == LedgerTransactionType.borrowing ||
                _type == LedgerTransactionType.transfer ||
                (_type == LedgerTransactionType.repayment &&
                    !_externalDebtPayment) ||
                _type.isReceivableFlow) &&
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
      final terms = _isRefund ? const TransactionTerms() : _buildTerms(amount);
      List<AccountPayment>? payments;
      if (!_isRefund &&
          !_familyFunded &&
          _type == LedgerTransactionType.expense) {
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
        payments = [AccountPayment(accountId!, primary), ...rest];
      }
      if (_isRefund) {
        await repository.saveRefund(
          id: record?.id,
          originalId: widget.refundFor!.id,
          accountId: accountId!,
          amountMinor: amount,
          advanceCancellationMinor: _advanceAmount.text.trim().isEmpty
              ? null
              : parseMoney(
                  _advanceAmount.text,
                  _sourceCurrency,
                  allowZero: true,
                ),
          occurredAt: _occurredAt,
          note: _noteController.text,
          status: status,
        );
      } else if (_familyFunded) {
        await repository.saveFamilyExpense(
          id: record?.id,
          amountMinor: amount,
          currencyCode: _familyCurrency,
          categories: terms.categories,
          occurredAt: _occurredAt,
          categoryId: _categoryId!,
          note: _noteController.text,
          status: status,
        );
      } else if (record == null) {
        await repository.addTransaction(
          type: _type,
          amountMinor: amount,
          occurredAt: _occurredAt,
          categoryId: _categoryId,
          accountId: accountId!,
          targetAccountId: _targetAccountId,
          payments: payments,
          settlement: settlement,
          terms: terms,
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
          accountId: accountId!,
          targetAccountId: _targetAccountId,
          payments: payments,
          settlement: settlement,
          terms: terms,
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

class _SplitCategoryInput {
  _SplitCategoryInput(this.categoryId, String amount)
    : amount = TextEditingController(text: amount);

  String categoryId;
  final TextEditingController amount;
}
