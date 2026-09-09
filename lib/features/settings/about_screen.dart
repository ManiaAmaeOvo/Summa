import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutSummaScreen extends StatelessWidget {
  const AboutSummaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于 Summa')),
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
                  ? '版本 ${snapshot.data!.version}  (${snapshot.data!.buildNumber})'
                  : '正在读取版本信息…',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 28),
          Card.filled(
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                '一款完全本地优先的个人记账工具。账户、负债、分类和账单默认只保存在你的设备上，无需登录，也不依赖后台服务器。',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('开发者'),
            subtitle: const Text('ManiaAmaeOvo'),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () => _openGitHub(context),
          ),
          const ListTile(
            leading: Icon(Icons.code),
            title: Text('协作构建'),
            subtitle: Text('OpenAI Codex · Flutter'),
          ),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('数据原则'),
            subtitle: Text('本地存储、明确导出、由用户掌控'),
          ),
          const ListTile(
            leading: Icon(Icons.balance_outlined),
            title: Text('软件许可'),
            subtitle: Text('PolyForm Noncommercial 1.0.0 · 仅限非商业用途'),
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
          .showSnackBar(const SnackBar(content: Text('无法打开 GitHub 主页')));
    }
  }
}
