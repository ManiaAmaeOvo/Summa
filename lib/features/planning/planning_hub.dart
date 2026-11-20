import 'package:flutter/material.dart';
import 'package:summa/app/widgets/ledger_surfaces.dart';
import 'package:summa/features/planning/debt_contracts_screen.dart';
import 'package:summa/features/planning/recurring_plans_screen.dart';
import 'package:summa/features/planning/savings_goals_screen.dart';
import 'package:summa/features/planning/spending_plans_screen.dart';
import 'package:summa/features/reports/cash_forecast_screen.dart';
import 'package:summa/l10n/l10n.dart';

class PlanningHub extends StatelessWidget {
  const PlanningHub({super.key});

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final destinations = [
      (
        labels.spendingPlans,
        Icons.pie_chart_outline,
        const SpendingPlansScreen(),
      ),
      (labels.recurringPlans, Icons.event_repeat, const RecurringPlansScreen()),
      (
        labels.debtContracts,
        Icons.request_quote_outlined,
        const DebtContractsScreen(),
      ),
      (labels.savingsGoals, Icons.savings_outlined, const SavingsGoalsScreen()),
    ];
    void open(Widget screen) => Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            leading: const LedgerIconMark(icon: Icons.timeline_outlined),
            trailing: const Icon(Icons.chevron_right),
            title: Text(labels.cashForecast),
            onTap: () => open(const CashForecastScreen()),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (index, (label, icon, screen))
                  in destinations.indexed) ...[
                if (index > 0)
                  const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: LedgerIconMark(icon: icon),
                  trailing: const Icon(Icons.chevron_right),
                  title: Text(label),
                  onTap: () => open(screen),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
