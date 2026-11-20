import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/analytics/financial_activity.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/transaction_terms.dart';

enum LedgerFunding {
  personal,
  familyDirect,
  entrusted,
  thirdParty,
  familySupport,
  externalRepayment,
  unclassified;

  bool includes(LedgerFunding actual) =>
      this == actual || this == personal && actual == thirdParty;
}

typedef LedgerDateRange = ({DateTime start, DateTime endExclusive});

class LedgerFilter {
  const LedgerFilter({
    this.range,
    this.currency,
    this.categoryId,
    this.accountId,
    this.funding,
  });

  final LedgerDateRange? range;
  final String? currency;
  final String? categoryId;
  final String? accountId;
  final LedgerFunding? funding;

  bool get hasDimensions =>
      categoryId != null || accountId != null || funding != null;
  bool get isActive => hasDimensions || currency != null || range != null;

  bool includesDate(DateTime time) =>
      range == null ||
      !time.isBefore(range!.start) && time.isBefore(range!.endExclusive);

  bool matches(LedgerRecord record) {
    if (!includesDate(record.occurredAt)) return false;
    final currencies = ledgerRecordCurrencies(record);
    if (!hasDimensions) {
      return currency == null || currencies.contains(currency);
    }
    return currencies
        .where((code) => currency == null || currency == code)
        .any((code) => _slices(record, code, accountId).any(_includesSlice));
  }

  bool _includesSlice(_Slice item) =>
      (categoryId == null ||
          categoryId == item.category?.id ||
          categoryId == item.category?.parentId) &&
      (accountId == null || item.accounts.contains(accountId)) &&
      (funding == null || funding!.includes(item.funding));
}

Set<String> ledgerRecordCurrencies(LedgerRecord record) => {
  record.currencyCode,
  if (record.settlement case final settlement?) settlement.currencyCode,
  for (final posting in record.accountPostings) posting.currencyCode,
};

typedef AnalysisCategory = ({
  String id,
  String name,
  String parentId,
  String parentName,
});
typedef AnalysisBreakdown = ({String id, String name, BigInt amountMinor});
typedef AnalysisSpendingPoint = ({DateTime date, BigInt amountMinor});

class LedgerAnalysis {
  const LedgerAnalysis({
    required this.activity,
    required this.incomeMinor,
    required this.borrowingMinor,
    required this.repaymentMinor,
    required this.expenseCategories,
    required this.incomeCategories,
    required this.spending,
    required this.accountFlows,
  });

  final FinancialActivity activity;
  final BigInt incomeMinor;
  final BigInt borrowingMinor;
  final BigInt repaymentMinor;
  final List<AnalysisBreakdown> expenseCategories;
  final List<AnalysisBreakdown> incomeCategories;
  final List<AnalysisSpendingPoint> spending;
  final List<AnalysisAccountFlow> accountFlows;
}

typedef AnalysisAccountFlow = ({
  String id,
  String name,
  BigInt inflowMinor,
  BigInt outflowMinor,
});

LedgerAnalysis analyzeLedger(
  Iterable<LedgerRecord> records,
  String currency,
  LedgerFilter filter,
) {
  final posted = records
      .where(
        (item) =>
            !item.isPending &&
            filter.includesDate(item.occurredAt) &&
            (filter.currency == null || filter.currency == currency),
      )
      .toList();
  final totals = _Totals();
  final expenses = <String, AnalysisBreakdown>{};
  final incomes = <String, AnalysisBreakdown>{};
  final spendingPoints = <AnalysisSpendingPoint>[];
  final accounts = <String, AnalysisAccountFlow>{};

  void addAccountFlow(_CashMovement movement) {
    final existing = accounts[movement.id];
    accounts[movement.id] = (
      id: movement.id,
      name: movement.name,
      inflowMinor: (existing?.inflowMinor ?? BigInt.zero) + movement.inflow,
      outflowMinor: (existing?.outflowMinor ?? BigInt.zero) + movement.outflow,
    );
  }

  void addCategory(
    Map<String, AnalysisBreakdown> groups,
    AnalysisCategory category,
    BigInt amount,
  ) {
    if (amount == BigInt.zero) return;
    // A selected parent shows its children; with no category, group by parent.
    final parent = filter.categoryId == null;
    final id = parent ? category.parentId : category.id;
    final name = parent ? category.parentName : category.name;
    groups[id] = (
      id: id,
      name: name,
      amountMinor: (groups[id]?.amountMinor ?? BigInt.zero) + amount,
    );
  }

  for (final record in posted) {
    var spending = BigInt.zero;
    if (!filter.hasDimensions) {
      if (record.currencyCode == currency) {
        spending = BigInt.from(record.spendingMinor);
        final amount = BigInt.from(record.signedAmountMinor);
        switch (record.type) {
          case LedgerTransactionType.income:
            totals.income += amount;
            addCategory(incomes, _category(record, record.categoryId), amount);
          case LedgerTransactionType.borrowing:
            totals.borrowing += amount;
          case LedgerTransactionType.repayment:
            totals.repayment += amount;
          default:
            break;
        }
        for (final item in record.spendingCategories) {
          addCategory(
            expenses,
            _category(record, item.categoryId),
            BigInt.from(item.amountMinor),
          );
        }
      }
      // A per-account breakdown shows actual movements on each cash account.
      if (record.type != LedgerTransactionType.adjustment) {
        for (final posting in record.accountPostings) {
          if (posting.currencyCode == currency &&
              posting.kind?.isPersonalCash == true) {
            addAccountFlow(
              _cashMovement(
                posting,
                BigInt.from(posting.debitMinor),
                record.isReversal,
              ),
            );
          }
        }
      }
    } else {
      for (final slice in _slices(
        record,
        currency,
        filter.accountId,
      ).where(filter._includesSlice)) {
        totals.add(slice);
        spending += slice.expense;
        final category = slice.category;
        if (category != null) {
          addCategory(expenses, category, slice.expense);
          addCategory(incomes, category, slice.income);
        }
        for (final movement in slice.cash) {
          addAccountFlow(movement);
        }
      }
    }
    if (spending != BigInt.zero) {
      spendingPoints.add((date: record.occurredAt, amountMinor: spending));
    }
  }

  return LedgerAnalysis(
    activity: filter.hasDimensions
        ? totals.activity
        : summarizeFinancialActivity(posted, currency),
    incomeMinor: totals.income,
    borrowingMinor: totals.borrowing,
    repaymentMinor: totals.repayment,
    expenseCategories: expenses.values
        .where((row) => row.amountMinor != BigInt.zero)
        .toList(),
    incomeCategories: incomes.values
        .where((row) => row.amountMinor != BigInt.zero)
        .toList(),
    spending: spendingPoints,
    accountFlows: accounts.values
        .where(
          (row) =>
              row.inflowMinor != BigInt.zero || row.outflowMinor != BigInt.zero,
        )
        .toList(),
  );
}

Iterable<AnalysisCategory> ledgerRecordCategories(LedgerRecord record) sync* {
  yield _category(record, record.categoryId);
  for (final item in record.terms.categories) {
    yield _category(record, item.categoryId);
  }
  if (record.terms.feeMinor > 0) {
    yield _category(record, financialFeeCategoryId);
  }
  if (record.terms.interestMinor > 0) {
    yield _category(record, financialInterestCategoryId);
  }
}

AnalysisCategory _category(LedgerRecord record, String id) {
  if (record.allocationLabels[id] case final item?) {
    return (
      id: id,
      name: item.name,
      parentId: item.parentId,
      parentName: item.parentName,
    );
  }
  if (id == financialFeeCategoryId || id == financialInterestCategoryId) {
    return (
      id: id,
      name: id,
      parentId: financialChargesCategoryId,
      parentName: financialChargesCategoryId,
    );
  }
  return (
    id: id,
    name: record.categoryName,
    parentId: record.parentCategoryId,
    parentName: record.parentCategoryName,
  );
}

typedef _CashMovement = ({
  String id,
  String name,
  BigInt inflow,
  BigInt outflow,
});

_CashMovement _cashMovement(
  AccountPosting posting,
  BigInt debit,
  bool reversal,
) {
  final out = reversal ? debit > BigInt.zero : debit.isNegative;
  return (
    id: posting.accountId,
    name: posting.accountName,
    inflow: out ? BigInt.zero : debit,
    outflow: out ? -debit : BigInt.zero,
  );
}

class _Slice {
  _Slice({
    required this.category,
    required this.accounts,
    required this.funding,
    BigInt? expense,
    BigInt? income,
    BigInt? borrowing,
    BigInt? repayment,
    this.cash = const [],
    this.internal = false,
  }) : expense = expense ?? BigInt.zero,
       income = income ?? BigInt.zero,
       borrowing = borrowing ?? BigInt.zero,
       repayment = repayment ?? BigInt.zero;

  final AnalysisCategory? category;
  final Set<String> accounts;
  final LedgerFunding funding;
  final BigInt expense, income, borrowing, repayment;
  final List<_CashMovement> cash;
  final bool internal;
}

LedgerFunding _funding(AccountKind? kind) => switch (kind) {
  AccountKind.familyDirect => LedgerFunding.familyDirect,
  AccountKind.entrustedFunds => LedgerFunding.entrusted,
  AccountKind.thirdPartyPayable => LedgerFunding.thirdParty,
  AccountKind.receivable || null => LedgerFunding.unclassified,
  _ => LedgerFunding.personal,
};

Iterable<_Slice> _slices(
  LedgerRecord record,
  String currency,
  String? accountId,
) sync* {
  final postings = record.accountPostings
      .where((p) => p.currencyCode == currency)
      .toList();
  final primaryCurrency = currency == record.currencyCode;
  final category = _category(record, record.categoryId);

  if (record.type == LedgerTransactionType.expense && primaryCurrency) {
    yield* _expenseSlices(record, postings, accountId);
    return;
  }

  final sourceKind = AccountKind.values.asNameMap()[record.accountKind];
  final targetKind = AccountKind.values.asNameMap()[record.targetAccountKind];
  final funding = record.needsReview
      ? LedgerFunding.unclassified
      : record.terms.externalDebtPayment
      ? LedgerFunding.externalRepayment
      : record.type == LedgerTransactionType.income &&
            record.parentCategoryId == 'income-parent-1'
      ? LedgerFunding.familySupport
      : _funding(record.type.collectsReceivable ? targetKind : sourceKind);
  final accounts = {
    for (final posting in postings) posting.accountId,
    if (primaryCurrency) record.accountId,
    if (record.targetAccountId case final target?)
      if (currency == (record.settlement?.currencyCode ?? record.currencyCode))
        target,
  };
  if (accounts.isEmpty) return;

  final amount = BigInt.from(record.signedAmountMinor);
  final internal =
      record.type == LedgerTransactionType.transfer &&
      record.accountPostings.length == 2 &&
      record.accountPostings.every(
        (posting) => posting.kind?.isPersonalCash == true,
      );
  bool isSelectedCash(AccountPosting leg) =>
      leg.kind?.isPersonalCash == true &&
      (accountId == null || leg.accountId == accountId);
  final cash = <_CashMovement>[];
  if (record.type != LedgerTransactionType.adjustment) {
    for (final leg in postings.where(isSelectedCash)) {
      final charges = leg.accountId == record.accountId && primaryCurrency
          ? record.direction * record.chargesMinor
          : 0;
      final debit = BigInt.from(leg.debitMinor) + BigInt.from(charges);
      if (debit != BigInt.zero) {
        cash.add(_cashMovement(leg, debit, record.isReversal));
      }
    }
  }
  yield _Slice(
    category: category,
    accounts: accounts,
    funding: funding,
    income: primaryCurrency && record.type == LedgerTransactionType.income
        ? amount
        : null,
    borrowing: primaryCurrency && record.type == LedgerTransactionType.borrowing
        ? amount
        : null,
    repayment: primaryCurrency && record.type == LedgerTransactionType.repayment
        ? amount
        : null,
    cash: cash,
    internal: internal && accountId == null,
  );

  if (!primaryCurrency || record.chargesMinor == 0) return;
  final source = postings
      .where((posting) => posting.accountId == record.accountId)
      .firstOrNull;
  for (final (id, value) in [
    (financialFeeCategoryId, record.terms.feeMinor),
    (financialInterestCategoryId, record.terms.interestMinor),
  ]) {
    if (value <= 0) continue;
    final signed = BigInt.from(record.direction * value);
    yield _Slice(
      category: _category(record, id),
      accounts: {record.accountId},
      funding: funding,
      expense: signed,
      cash: [
        if (source != null && isSelectedCash(source))
          _cashMovement(source, -signed, record.isReversal),
      ],
    );
  }
}

Iterable<_Slice> _expenseSlices(
  LedgerRecord record,
  List<AccountPosting> postings,
  String? accountId,
) sync* {
  final advance = record.terms.advance;
  final total = BigInt.from(record.amountMinor);
  final net = BigInt.from(record.amountMinor - (advance?.amountMinor ?? 0));
  final sign = BigInt.from(record.isRefund ? -1 : record.direction);
  final legs = postings
      .where(
        (leg) => leg.accountId != advance?.accountId && leg.debitMinor != 0,
      )
      .toList();
  final paid = <BigInt>[
    for (final leg in legs) BigInt.from(leg.debitMinor).abs(),
  ];
  final missing = total - paid.fold(BigInt.zero, (sum, part) => sum + part);
  if (missing.isNegative) {
    // Invalid historical data stays attributable to the transaction only.
    yield _Slice(
      category: _category(record, record.categoryId),
      accounts: {record.accountId},
      funding: LedgerFunding.unclassified,
      expense: net * sign,
    );
    return;
  }
  if (missing > BigInt.zero) paid.add(missing);
  final spent = _proportional(net, paid, total);
  final pendingCapacity = List.of(spent);

  final categories = record.terms.categories.isEmpty
      ? [(categoryId: record.categoryId, amountMinor: net.toInt())]
      : record.terms.categories;
  var remaining = net;
  for (final part in categories) {
    final amount = BigInt.from(part.amountMinor);
    final pieces = _proportional(amount, pendingCapacity, remaining);
    for (final (index, value) in pieces.indexed) {
      if (value == BigInt.zero) continue;
      pendingCapacity[index] -= value;
      final leg = index < legs.length ? legs[index] : null;
      final signed = sign * value;
      yield _Slice(
        category: _category(record, part.categoryId),
        accounts: {leg?.accountId ?? record.accountId},
        funding: leg == null || leg.needsReview
            ? LedgerFunding.unclassified
            : _funding(leg.kind),
        expense: signed,
        cash: [
          if (leg != null && leg.kind?.isPersonalCash == true)
            _cashMovement(leg, -signed, record.isReversal),
        ],
      );
    }
    remaining -= amount;
  }

  if (advance != null) {
    for (final (index, amount) in paid.indexed) {
      final portion = amount - spent[index];
      if (portion == BigInt.zero) continue;
      final leg = index < legs.length ? legs[index] : null;
      yield _Slice(
        category: null,
        accounts: {leg?.accountId ?? record.accountId, advance.accountId},
        funding: leg == null || leg.needsReview
            ? LedgerFunding.unclassified
            : _funding(leg.kind),
        cash: [
          if (leg != null &&
              leg.kind?.isPersonalCash == true &&
              (accountId == null || accountId == leg.accountId))
            _cashMovement(leg, -sign * portion, record.isReversal),
        ],
      );
    }
  }
}

List<BigInt> _proportional(BigInt amount, List<BigInt> weights, BigInt total) {
  // Cumulative rounding preserves the exact payer and category totals.
  var running = BigInt.zero;
  var previous = BigInt.zero;
  if (total == BigInt.zero) return List.filled(weights.length, BigInt.zero);
  final portions = <BigInt>[];
  for (final weight in weights) {
    running += weight;
    final cumulative = running * amount ~/ total;
    portions.add(cumulative - previous);
    previous = cumulative;
  }
  return portions;
}

class _Totals {
  var gross = BigInt.zero;
  var personal = BigInt.zero;
  var family = BigInt.zero;
  var entrusted = BigInt.zero;
  var thirdParty = BigInt.zero;
  var support = BigInt.zero;
  var income = BigInt.zero;
  var borrowing = BigInt.zero;
  var repayment = BigInt.zero;
  var inflow = BigInt.zero;
  var outflow = BigInt.zero;

  void add(_Slice slice) {
    gross += slice.expense;
    income += slice.income;
    borrowing += slice.borrowing;
    repayment += slice.repayment;
    switch (slice.funding) {
      case LedgerFunding.personal:
        personal += slice.expense;
      case LedgerFunding.thirdParty:
        personal += slice.expense;
        thirdParty += slice.expense;
      case LedgerFunding.familyDirect:
        family += slice.expense;
      case LedgerFunding.entrusted:
        entrusted += slice.expense;
      default:
        break;
    }
    for (final movement
        in slice.internal ? const <_CashMovement>[] : slice.cash) {
      inflow += movement.inflow;
      outflow += movement.outflow;
      if (slice.funding == LedgerFunding.familySupport) {
        support += movement.inflow;
      }
    }
  }

  FinancialActivity get activity => (
    grossSpending: gross,
    personalSpending: personal,
    familyDirectSpending: family,
    entrustedSpending: entrusted,
    thirdPartyPayableSpending: thirdParty,
    unclassifiedSpending: gross - personal - family - entrusted,
    familySupportReceived: support,
    personalCashInflow: inflow,
    personalCashOutflow: outflow,
  );
}
