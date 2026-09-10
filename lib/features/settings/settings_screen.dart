import 'package:flutter/material.dart';
import 'package:ledger_pro/app/locale_controller.dart';
import 'package:ledger_pro/features/categories/category_management_screen.dart';
import 'package:ledger_pro/features/settings/about_screen.dart';
import 'package:ledger_pro/features/settings/data_management_screen.dart';
import 'package:ledger_pro/features/settings/help_screen.dart';
import 'package:ledger_pro/l10n/l10n.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.ledger, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.category_outlined,
                  title: l10n.categoryManagement,
                  subtitle: l10n.categoryManagementSubtitle,
                  screen: const CategoryManagementScreen(),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.storage_outlined,
                  title: l10n.dataAndBackup,
                  subtitle: l10n.dataAndBackupSubtitle,
                  screen: const DataManagementScreen(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.app, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: Text(l10n.language),
                  subtitle: Text(_languageLabel(context)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _chooseLanguage(context),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.menu_book_outlined,
                  title: l10n.userGuide,
                  subtitle: l10n.userGuideSubtitle,
                  screen: const HelpScreen(),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: l10n.aboutSumma,
                  subtitle: l10n.aboutSummaSubtitle,
                  screen: const AboutSummaScreen(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _languageLabel(BuildContext context) =>
      switch (LocaleController.instance.value) {
        AppLanguage.system => context.l10n.languageSystem,
        AppLanguage.english => context.l10n.languageEnglish,
        AppLanguage.simplifiedChinese => context.l10n.languageSimplifiedChinese,
      };

  Future<void> _chooseLanguage(BuildContext context) async {
    final l10n = context.l10n;
    final selected = await showDialog<AppLanguage>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.language),
        children: [
          RadioGroup<AppLanguage>(
            groupValue: LocaleController.instance.value,
            onChanged: (value) => Navigator.pop(context, value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<AppLanguage>(
                  value: AppLanguage.system,
                  title: Text(l10n.languageSystem),
                ),
                RadioListTile<AppLanguage>(
                  value: AppLanguage.english,
                  title: Text(l10n.languageEnglish),
                ),
                RadioListTile<AppLanguage>(
                  value: AppLanguage.simplifiedChinese,
                  title: Text(l10n.languageSimplifiedChinese),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected != null) await LocaleController.instance.setLanguage(selected);
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.screen,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget screen;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ),
  );
}
