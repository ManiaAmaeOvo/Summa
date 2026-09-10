import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ledger_pro/l10n/l10n.dart';

class AboutSummaScreen extends StatelessWidget {
  const AboutSummaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutSumma)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.auto_graph_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Summa',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) => Text(
              snapshot.hasData
                  ? l10n.versionLabel(
                      snapshot.data!.version,
                      snapshot.data!.buildNumber,
                    )
                  : l10n.readingVersion,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 28),
          Card.filled(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(l10n.aboutDescription, textAlign: TextAlign.center),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.developer),
            subtitle: const Text('ManiaAmaeOvo'),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () => _openGitHub(context),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: Text(l10n.builtWith),
            subtitle: const Text('OpenAI Codex · Flutter'),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.dataPrinciples),
            subtitle: Text(l10n.dataPrinciplesValue),
          ),
          ListTile(
            leading: const Icon(Icons.balance_outlined),
            title: Text(l10n.softwareLicense),
            subtitle: Text(l10n.softwareLicenseValue),
          ),
        ],
      ),
    );
  }

  Future<void> _openGitHub(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse('https://github.com/ManiaAmaeOvo'),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.cannotOpenGitHub)));
    }
  }
}
