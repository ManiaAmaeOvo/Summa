import 'package:flutter/material.dart';
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
      (
        labels.cashForecast,
        Icons.timeline_outlined,
        const CashForecastScreen(),
      ),
    ];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: destinations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final (label, icon, destination) = destinations[index];
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(icon),
            trailing: const Icon(Icons.chevron_right),
            title: Text(label),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => destination),
            ),
          ),
        );
      },
    );
  }
}
