import 'package:flutter/material.dart';
import 'package:ledger_pro/l10n/l10n.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.userGuide)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card.filled(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(l10n.helpIntro),
            ),
          ),
          _HelpSection(
            icon: Icons.edit_note_rounded,
            title: l10n.helpTransactionsTitle,
            paragraphs: [
              l10n.helpTransactions1,
              l10n.helpTransactions2,
              l10n.helpTransactions3,
            ],
          ),
          _HelpSection(
            icon: Icons.account_balance_wallet_outlined,
            title: l10n.helpAccountsTitle,
            paragraphs: [l10n.helpAccounts1, l10n.helpAccounts2],
          ),
          _HelpSection(
            icon: Icons.data_object_rounded,
            title: l10n.helpJsonTitle,
            paragraphs: [l10n.helpJson1, l10n.helpJson2, l10n.helpJson3],
          ),
          _HelpSection(
            icon: Icons.pie_chart_outline_rounded,
            title: l10n.helpReportsTitle,
            paragraphs: [l10n.helpReports1, l10n.helpReports2],
          ),
          _HelpSection(
            icon: Icons.settings_backup_restore_rounded,
            title: l10n.helpBackupTitle,
            paragraphs: [l10n.helpBackup1, l10n.helpBackup2, l10n.helpBackup3],
          ),
          _HelpSection(
            icon: Icons.restart_alt_rounded,
            title: l10n.helpResetTitle,
            paragraphs: [l10n.helpReset1, l10n.helpReset2],
          ),
          _HelpSection(
            icon: Icons.privacy_tip_outlined,
            title: l10n.helpSecurityTitle,
            paragraphs: [l10n.helpSecurity1, l10n.helpSecurity2],
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.icon,
    required this.title,
    required this.paragraphs,
  });

  final IconData icon;
  final String title;
  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 10),
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      leading: Icon(icon),
      title: Text(title),
      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < paragraphs.length; index++) ...[
          if (index > 0) const SizedBox(height: 10),
          Text(paragraphs[index]),
        ],
      ],
    ),
  );
}
