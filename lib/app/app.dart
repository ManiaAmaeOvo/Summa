import 'package:flutter/material.dart';
import 'package:ledger_pro/app/theme/ledger_scroll_behavior.dart';
import 'package:ledger_pro/app/theme/ledger_theme.dart';
import 'package:ledger_pro/features/dashboard/dashboard_screen.dart';

class SummaApp extends StatelessWidget {
  const SummaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Summa',
      debugShowCheckedModeBanner: false,
      theme: LedgerTheme.light,
      darkTheme: LedgerTheme.dark,
      themeMode: ThemeMode.system,
      scrollBehavior: const LedgerScrollBehavior(),
      home: const DashboardScreen(),
    );
  }
}
