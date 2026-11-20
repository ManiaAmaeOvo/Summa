import 'package:flutter/material.dart';
import 'package:summa/features/accounts/account_overview_screen.dart';
import 'package:summa/features/dashboard/financial_home.dart';
import 'package:summa/features/dashboard/transaction_browser.dart';
import 'package:summa/features/import_export/csv_import_screen.dart';
import 'package:summa/features/import_export/structured_import_screen.dart';
import 'package:summa/features/planning/planning_hub.dart';
import 'package:summa/features/reports/report_screen.dart';
import 'package:summa/features/settings/settings_screen.dart';
import 'package:summa/features/transaction_editor/add_expense_sheet.dart';
import 'package:summa/l10n/l10n.dart';

enum _Destination { home, transactions, accounts, planning, reports }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  var _selected = _Destination.home;
  final _visited = {_Destination.home};

  void _select(_Destination destination) => setState(() {
    _selected = destination;
    _visited.add(destination);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tabs = _Destination.values;
    final labels = [
      l10n.homeTab,
      l10n.transactions,
      l10n.accounts,
      l10n.planningTab,
      l10n.reports,
    ];
    final navigationLabels = [...labels]..[1] = l10n.transactionTab;
    final safeScreenWidth =
        MediaQuery.sizeOf(context).width -
        MediaQuery.paddingOf(context).horizontal;
    final textScale = MediaQuery.textScalerOf(context);
    final labelsFit = navigationLabels.every(
      (label) =>
          TextPainter.computeWidth(
            text: TextSpan(
              text: label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            textDirection: Directionality.of(context),
            textScaler: textScale,
          ) <=
          safeScreenWidth / tabs.length - 8,
    );
    const icons = [
      (Icons.home_outlined, Icons.home),
      (Icons.receipt_long_outlined, Icons.receipt_long),
      (Icons.account_balance_wallet_outlined, Icons.account_balance_wallet),
      (Icons.event_note_outlined, Icons.event_note),
      (Icons.insights_outlined, Icons.insights),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(switch (_selected) {
          _Destination.home => l10n.appName,
          _Destination.accounts => l10n.accountBalances,
          _ => labels[_selected.index],
        }),
        actions: [
          if (_selected == _Destination.transactions) ...[
            IconButton(
              tooltip: l10n.csvImport,
              onPressed: () => _open(const CsvImportScreen()),
              icon: const Icon(Icons.upload_file_outlined),
            ),
            IconButton(
              tooltip: l10n.codeImport,
              onPressed: () => _open(const StructuredImportScreen()),
              icon: const Icon(Icons.data_object),
            ),
          ],
          IconButton(
            tooltip: l10n.settings,
            onPressed: () => _open(const SettingsScreen()),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: IndexedStack(
              index: _selected.index,
              children: [
                for (final tab in tabs)
                  if (_visited.contains(tab))
                    switch (tab) {
                      _Destination.home => FinancialHome(
                        onAddTransaction: _addTransaction,
                      ),
                      _Destination.transactions => TransactionBrowser(
                        onOpenAccounts: () => _select(_Destination.accounts),
                      ),
                      _Destination.accounts => const AccountOverviewScreen(),
                      _Destination.planning => const PlanningHub(),
                      _Destination.reports => const ReportScreen(),
                    }
                  else
                    const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _selected == _Destination.transactions
          ? FloatingActionButton(
              onPressed: _addTransaction,
              tooltip: l10n.addTransaction,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selected.index,
        labelBehavior: labelsFit
            ? NavigationDestinationLabelBehavior.alwaysShow
            : textScale.scale(12) >= 21
            ? NavigationDestinationLabelBehavior.alwaysHide
            : NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: (index) => _select(tabs[index]),
        destinations: [
          for (final tab in tabs)
            NavigationDestination(
              icon: Icon(icons[tab.index].$1),
              selectedIcon: Icon(icons[tab.index].$2),
              label: navigationLabels[tab.index],
            ),
        ],
      ),
    );
  }

  void _addTransaction() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const TransactionEditorSheet(),
  );

  void _open(Widget screen) =>
      Navigator.push<void>(context, MaterialPageRoute(builder: (_) => screen));
}
