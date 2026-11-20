import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/app/widgets/currency_selector.dart';
import 'package:summa/app/widgets/ledger_surfaces.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/analytics/cash_forecast.dart';
import 'package:summa/domain/analytics/financial_activity.dart';
import 'package:summa/domain/analytics/financial_home.dart';
import 'package:summa/domain/planning/planning_date.dart';
import 'package:summa/domain/planning/spending_plan.dart';
import 'package:summa/features/planning/spending_plans_screen.dart';
import 'package:summa/features/reconciliation/reconciliation_screen.dart';
import 'package:summa/features/reports/cash_forecast_screen.dart';
import 'package:summa/features/reports/historical_analysis_screen.dart';
import 'package:summa/features/valuation/valuation_screen.dart';
import 'package:summa/l10n/default_ledger_labels.dart';
import 'package:summa/l10n/l10n.dart';

class FinancialHome extends ConsumerStatefulWidget {
  const FinancialHome({super.key, required this.onAddTransaction});

  final VoidCallback onAddTransaction;

  @override
  ConsumerState<FinancialHome> createState() => _FinancialHomeState();
}

class _FinancialHomeState extends ConsumerState<FinancialHome> {
  String? _currency;

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final input = ref.watch(cashForecastInputsProvider);
    return input.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(cashForecastInputsProvider),
          child: Text('${labels.homeLoadFailed} ${labels.retry}'),
        ),
      ),
      data: _content,
    );
  }

  Widget _content(CashForecastInputs input) {
    final labels = context.l10n;
    final theme = Theme.of(context);
    final budgets = ref.watch(spendingPlansProvider);
    final savings = ref.watch(savingsAllocationsProvider);
    final baseCurrency = ref
        .watch(valuationSettingsProvider)
        .value
        ?.baseCurrency;
    final currencies = currencyOptions([
      ...input.balances.map((account) => account.currencyCode),
      ...input.currencies,
      for (final plan in budgets.value ?? const <SpendingPlan>[])
        if (!plan.archived) plan.draft.currency,
    ]);
    final currency = [_currency, baseCurrency].whereType<String>().firstWhere(
      currencies.contains,
      orElse: () => currencies.first,
    );
    final now = DateTime.now();
    final today = planningDay(now);
    final month = DateTime(now.year, now.month);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final balances = balancesThroughToday(
      input.balances,
      input.transactions,
      now,
    );
    final monthActivity = summarizeFinancialActivity(
      input.transactions.where(
        (record) =>
            !record.occurredAt.isBefore(month) &&
            record.occurredAt.isBefore(tomorrow),
      ),
      currency,
    );
    final forecast = forecastCash(
      input,
      currency: currency,
      today: now,
      horizonDays: 7,
    );
    final obligations = [
      for (final day in forecast.days)
        for (final event in day.events)
          if (event.included &&
              event.changeMinor.isNegative &&
              event.source != CashForecastSource.futurePosted)
            event,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        NetWorthValuationCard(
          balances: balances,
          highlighted: true,
          action: FilledButton.icon(
            onPressed: widget.onAddTransaction,
            icon: const Icon(Icons.add),
            label: Text(labels.addTransaction),
          ),
        ),
        const SizedBox(height: 4),
        _HomeSection(
          title: labels.availableFunds,
          icon: Icons.account_balance_wallet_outlined,
          trailing: currencies.length > 1
              ? CurrencySelector(
                  currencies: currencies,
                  value: currency,
                  label: labels.summaryCurrency,
                  compact: true,
                  onChanged: (value) => setState(() => _currency = value),
                )
              : null,
          children: [
            savings.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => TextButton(
                onPressed: () => ref.invalidate(savingsAllocationsProvider),
                child: Text(labels.retry),
              ),
              data: (allocations) => Text(
                formatMoneyTotal(
                  availablePersonalCash(balances, allocations, currency),
                  currency,
                ),
                style: ledgerAmountStyle(theme.textTheme.headlineSmall),
              ),
            ),
            Text(
              labels.availableFundsHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        _HomeSection(
          title: labels.expenseThisMonth,
          icon: Icons.receipt_long_outlined,
          children: [
            _HomeAmount(
              label: labels.grossSpending,
              value: monthActivity.grossSpending,
              currency: currency,
            ),
            _HomeAmount(
              label: labels.personalSpending,
              value: monthActivity.personalSpending,
              currency: currency,
            ),
            TextButton.icon(
              onPressed: () =>
                  _open(HistoricalAnalysisScreen(initialCurrency: currency)),
              icon: const Icon(Icons.insights_outlined),
              label: Text(labels.historicalAnalysis),
            ),
          ],
        ),
        _HomeSection(
          title: labels.homeBudgetRemaining,
          icon: Icons.pie_chart_outline,
          children: [
            budgets.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => Text(labels.spendingPlansLoadFailed),
              data: (all) {
                final rows = [
                  for (final plan in all)
                    if (!plan.archived &&
                        plan.draft.currency == currency &&
                        plan.draft.scope != SpendingScope.allowance)
                      if (plan.draft.periodIndex(today) case final index?)
                        _HomeAmount(
                          label: plan.draft.name,
                          value: summarizeSpendingPlan(
                            plan,
                            input.transactions,
                            periodIndex: index,
                            today: now,
                          ).remainingMinor,
                          currency: currency,
                        ),
                ];
                return rows.isEmpty
                    ? Text(labels.homeNoBudgets)
                    : Column(children: rows);
              },
            ),
            TextButton(
              onPressed: () => _open(const SpendingPlansScreen()),
              child: Text(labels.spendingPlans),
            ),
          ],
        ),
        _HomeSection(
          title: labels.homeObligations,
          icon: Icons.event_outlined,
          children: [
            if (obligations.isEmpty) Text(labels.homeNoObligations),
            for (final event in obligations)
              _HomeAmount(
                label: event.name,
                value: event.changeMinor.abs(),
                currency: currency,
                detail: [
                  cashForecastSourceLabel(context, event.source),
                  event.dueOn.isBefore(today)
                      ? labels.forecastOverdueSince(
                          MaterialLocalizations.of(context)
                              .formatShortDate(event.dueOn),
                        )
                      : MaterialLocalizations.of(context)
                            .formatShortDate(event.dueOn),
                ].join(' · '),
              ),
            TextButton(
              onPressed: () => _open(const CashForecastScreen()),
              child: Text(labels.cashForecast),
            ),
          ],
        ),
        _HomeSection(
          title: labels.homeReconciliation,
          icon: Icons.rule_outlined,
          children: [_ReconciliationItems(balances: input.balances)],
        ),
      ],
    );
  }

  void _open(Widget screen) =>
      Navigator.push<void>(context, MaterialPageRoute(builder: (_) => screen));
}

class _ReconciliationItems extends ConsumerWidget {
  const _ReconciliationItems({required this.balances});

  final List<AccountBalance> balances;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = context.l10n;
    final providers = [
      for (final account in balances) balanceCheckpointsProvider(account.id),
    ];
    final results = [for (final provider in providers) ref.watch(provider)];
    final rows = [
      for (final (index, result) in results.indexed)
        if (result.value
                ?.where((checkpoint) => !checkpoint.isVoided)
                .firstOrNull
            case final latest?)
          if (!latest.isBalanced)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                DefaultLedgerLabels.accountName(
                  Localizations.localeOf(context),
                  balances[index].id,
                  balances[index].name,
                ),
              ),
              subtitle: Text(
                '${labels.checkpointUnbalanced} · '
                '${formatMoneyTotal(latest.differenceMinor, latest.currencyCode)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ReconciliationScreen(account: balances[index]),
                ),
              ),
            ),
    ];
    final loading = results.any((result) => result.isLoading);
    final failed = results.any((result) => result.hasError);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...rows,
        if (loading) const LinearProgressIndicator(),
        if (failed)
          TextButton(
            onPressed: () {
              for (final (index, result) in results.indexed) {
                if (result.hasError) ref.invalidate(providers[index]);
              }
            },
            child: Text(labels.retry),
          ),
        if (!loading && !failed && rows.isEmpty)
          Text(labels.homeNoReconciliation),
      ],
    );
  }
}

class _HomeSection extends StatelessWidget {
  const _HomeSection({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (trailing case final control?) ...[
                const SizedBox(width: 8),
                control,
              ],
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
}

class _HomeAmount extends StatelessWidget {
  const _HomeAmount({
    required this.label,
    required this.value,
    required this.currency,
    this.detail,
  });

  final String label;
  final BigInt value;
  final String currency;
  final String? detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: LedgerValueRow(
      label: label,
      value: formatMoneyTotal(value, currency),
      detail: detail,
      valueStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: value.isNegative ? Theme.of(context).colorScheme.error : null,
      ),
    ),
  );
}
