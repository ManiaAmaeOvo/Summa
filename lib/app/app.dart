import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ledger_pro/app/locale_controller.dart';
import 'package:ledger_pro/app/theme/ledger_scroll_behavior.dart';
import 'package:ledger_pro/app/theme/ledger_theme.dart';
import 'package:ledger_pro/features/dashboard/dashboard_screen.dart';
import 'package:ledger_pro/l10n/app_localizations.dart';

class SummaApp extends StatelessWidget {
  const SummaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: LocaleController.instance,
      builder: (context, language, _) => MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        debugShowCheckedModeBanner: false,
        theme: LedgerTheme.light,
        darkTheme: LedgerTheme.dark,
        themeMode: ThemeMode.system,
        locale: LocaleController.instance.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        scrollBehavior: const LedgerScrollBehavior(),
        home: const DashboardScreen(),
      ),
    );
  }
}
