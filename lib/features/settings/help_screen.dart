import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('使用说明')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: const [
          Card.filled(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('Summa 完全本地运行。建议先校准账户余额，再检查分类并开始记账；重要数据请定期导出完整备份。'),
            ),
          ),
          _HelpSection(
            icon: Icons.edit_note_rounded,
            title: '记账与交易类型',
            paragraphs: [
              '首页点击“记一笔”，可记录支出、收入、借入、还款和个人账户转账。日期默认使用当前时间，也可手动修改。',
              '借入会同时增加负债和目标账户余额，不算收入；还款同时减少付款余额和负债，不算支出；转账不进入收支统计。',
              '余额不足、超额还款或无效账户流向会被拒绝。点击已有账单可以编辑或软删除。',
            ],
          ),
          _HelpSection(
            icon: Icons.account_balance_wallet_outlined,
            title: '账户与分类',
            paragraphs: [
              '底部“账户”展示个人流动资产、待偿负债、流动净资产和受托/授权资金。点击账户可校准当前余额；校准不会产生虚假收入或支出。',
              '账户可新增或停用。设置中的分类管理分别维护收入和支出的两级分类；账单实际选择二级分类，每个一级分类保留“其他”兜底项。',
            ],
          ),
          _HelpSection(
            icon: Icons.data_object_rounded,
            title: 'JSON 代码块导入',
            paragraphs: [
              '首页右上角代码图标可粘贴单笔或批量 JSON，适合把账单截图经 OCR 或语言模型整理后导入。',
              '流程为解析校验、逐条预览和编辑、确认数量、原子写入。未知账户可自动创建，未知分类需要先创建或在预览中修正。',
              '金额使用正数十进制字符串，时间使用 ISO 8601，分类写作“一级/二级”。',
            ],
          ),
          _HelpSection(
            icon: Icons.pie_chart_outline_rounded,
            title: '报表与导出',
            paragraphs: [
              '底部“报表”支持日报、周报、月报和年报，并展示收支分类饼图、支出趋势和负债走势。',
              '账单可按本周、本月、本年、全部或自选时间段导出为 JSON、CSV 或 Markdown。账单导出用于分析，不等同于可还原整个软件的完整备份。',
            ],
          ),
          _HelpSection(
            icon: Icons.settings_backup_restore_rounded,
            title: '备份、合并与回档',
            paragraphs: [
              '每次启动后的第一次成功修改前自动保存完整状态，最多保留最近 5 个节点；失败操作不会占用节点。',
              '手动备份可保存为软件内节点或导出到外部。点击本地节点可预览并覆盖回档，菜单中还可合并、重命名手动节点或删除。',
              '软件内节点位于设置页所示的应用专属目录，会随卸载或恢复出厂而删除；长期保存请选择导出或分享。',
            ],
          ),
          _HelpSection(
            icon: Icons.restart_alt_rounded,
            title: '重置范围',
            paragraphs: [
              '“重置账单与账户”清空账单和自定义账户，将默认账户归零，但保留分类和备份。',
              '“恢复出厂设置”还会恢复默认分类并删除全部软件内备份。外部导出的文件不受影响。',
            ],
          ),
          _HelpSection(
            icon: Icons.privacy_tip_outlined,
            title: '数据安全',
            paragraphs: [
              '账本默认仅保存在设备上。卸载通常会删除数据库和本地节点，换机或卸载前必须导出完整备份。',
              '完整备份包含敏感财务信息，请只保存到可信位置，不要把真实备份上传到公开 Issue。',
            ],
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
