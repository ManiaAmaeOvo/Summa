import 'package:flutter_test/flutter_test.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/analytics/financial_home.dart';
import 'package:summa/domain/analytics/ledger_analysis.dart';
import 'package:summa/domain/analytics/ledger_history.dart';
import 'package:summa/domain/planning/savings_goal.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/transaction_source.dart';

void main() {
  test('history uses posting dates, archive dates and original currency', () {
    final inputs = LedgerHistoryInputs(
      balances: [
        _balance('cash', 10000, 7000, createdAt: DateTime(2025, 3, 1)),
        _balance('debt', 2000, 1500, kind: AccountKind.creditLine),
        _balance('archived', 3000, 3000, archivedAt: DateTime(2025, 3, 10)),
        _balance('new', 600, 600, createdAt: DateTime(2025, 3, 21)),
        _balance('external', 500, 500, kind: AccountKind.entrustedFunds),
        _balance('jpy', 512, 512, currency: 'JPY'),
      ],
      transactions: [
        _movement('cash', -1000, DateTime(2025, 2, 8)),
        _movement('cash', -2000, DateTime(2025, 3, 8)),
        _movement('cash', -700, DateTime(2025, 3, 21)),
        _movement('cash', -500, DateTime(2025, 3, 9), pending: true),
        _movement(
          'debt',
          500,
          DateTime(2025, 3, 8),
          kind: AccountKind.creditLine,
        ),
      ],
    );
    final points = analyzeLedgerHistory(
      inputs,
      today: DateTime(2025, 3, 20),
      currency: 'CNY',
      interval: LedgerHistoryInterval.month,
    );
    expect(points, hasLength(7));
    expect(points[points.length - 3].netWorthMinor, BigInt.from(1000));
    expect(points[points.length - 2].netWorthMinor, BigInt.from(10000));
    expect(points.last.netWorthMinor, BigInt.from(5500));
    expect(points.last.range.endExclusive, DateTime(2025, 3, 21));
    expect(points.last.analysis.activity.grossSpending, BigInt.from(2500));
    expect(
      points.last.analysis.activity.personalCashOutflow,
      BigInt.from(2000),
    );
    final yen = analyzeLedgerHistory(
      inputs,
      today: DateTime(2025, 3, 20),
      currency: 'JPY',
      interval: LedgerHistoryInterval.year,
    );
    expect(yen, hasLength(4));
    expect(yen.last.netWorthMinor, BigInt.from(512));
    expect(yen.last.analysis.activity.grossSpending, BigInt.zero);
  });

  test('available cash removes future postings and clamps reserved funds by account', () {
    final now = DateTime(2025, 3, 20);
    final today = balancesThroughToday(
      [
        _balance('cash', 1000, 1200),
        _balance('bank', 800, 800, kind: AccountKind.bank),
        _balance('receivable', 5000, 5000, kind: AccountKind.receivable),
        _balance('debt', 400, 600, kind: AccountKind.creditLine),
      ],
      [
        _movement('cash', 200, DateTime(2025, 3, 21)),
        _movement(
          'debt',
          -200,
          DateTime(2025, 3, 21),
          kind: AccountKind.creditLine,
        ),
        _movement('bank', 500, DateTime(2025, 3, 21), pending: true),
      ],
      now,
    );
    expect(today.map((account) => account.currentBalanceMinor), [
      1000,
      800,
      5000,
      400,
    ]);
    final savings = SavingsAccountAllocation(
      accountId: 'cash',
      accountName: 'cash',
      currency: 'CNY',
      archived: false,
      balanceMinor: 1200,
      goals: [
        SavingsGoal(
          id: 'goal',
          draft: const SavingsGoalDraft(
            name: 'Reserve',
            accountId: 'cash',
            currency: 'CNY',
            targetMinor: 1100,
            priority: SavingsPriority.normal,
          ),
          activity: [
            (id: 'reservation', changeMinor: 1100, recordedAt: now, note: ''),
          ],
        ),
      ],
    );
    expect(availablePersonalCash(today, [savings], 'CNY'), BigInt.from(800));
  });

  test(
    'channel and counterparty must match the same original statement row',
    () {
      const row1 = TransactionSource(
        batchId: 'a',
        batchName: 'wallet-a.csv',
        line: 2,
        cells: {'payment_channel': 'Wallet A', 'merchant': 'Bakery'},
      );
      const row2 = TransactionSource(
        batchId: 'b',
        batchName: 'wallet-b.csv',
        line: 3,
        cells: {'付款方式': 'Wallet B', '交易对方': 'Market'},
      );
      final record = _movement(
        'cash',
        -100,
        DateTime(2025, 3, 5),
        sources: [row1, row2],
      );
      expect(
        const LedgerFilter(
          channel: 'Wallet B',
          counterparty: 'Market',
        ).matches(record),
        isTrue,
      );
      expect(
        const LedgerFilter(
          channel: 'Wallet A',
          counterparty: 'Market',
        ).matches(record),
        isFalse,
      );
    },
  );
}

AccountBalance _balance(
  String id,
  int opening,
  int current, {
  AccountKind kind = AccountKind.cash,
  String currency = 'CNY',
  DateTime? createdAt,
  DateTime? archivedAt,
}) => AccountBalance(
  id: id,
  name: id,
  kind: kind,
  openingBalanceMinor: opening,
  currentBalanceMinor: current,
  currencyCode: currency,
  createdAt: createdAt,
  archivedAt: archivedAt,
);

LedgerRecord _movement(
  String account,
  int debit,
  DateTime date, {
  bool pending = false,
  AccountKind kind = AccountKind.cash,
  List<TransactionSource> sources = const [],
}) => LedgerRecord(
  id: '$account-$date',
  type: LedgerTransactionType.expense,
  amountMinor: debit.abs(),
  occurredAt: date,
  parentCategoryId: 'food',
  parentCategoryName: 'Food',
  categoryId: 'lunch',
  categoryName: 'Lunch',
  accountId: account,
  accountName: account,
  accountKind: kind.name,
  status: pending ? LedgerPostingStatus.pending : LedgerPostingStatus.posted,
  accountPostings: [
    AccountPosting(
      accountId: account,
      accountName: account,
      accountKind: kind.name,
      debitMinor: debit,
      needsReview: false,
    ),
  ],
  sources: sources,
  note: '',
);
