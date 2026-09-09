import 'package:flutter/material.dart';
import 'package:ledger_pro/features/categories/category_management_screen.dart';
import 'package:ledger_pro/features/settings/about_screen.dart';
import 'package:ledger_pro/features/settings/data_management_screen.dart';
import 'package:ledger_pro/features/settings/help_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('账本', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.category_outlined,
                  title: '分类管理',
                  subtitle: '维护收入和支出的两级分类',
                  screen: const CategoryManagementScreen(),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.storage_outlined,
                  title: '数据与备份',
                  subtitle: '本地节点、导出、恢复与重置',
                  screen: const DataManagementScreen(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('应用', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          const Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.menu_book_outlined,
                  title: '使用说明',
                  subtitle: '功能介绍、操作方法与数据安全',
                  screen: HelpScreen(),
                ),
                Divider(height: 1),
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: '关于 Summa',
                  subtitle: '版本、简介与开发者信息',
                  screen: AboutSummaScreen(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
