# Summa

**简体中文** | [English](README.md)

一款完全本地优先、面向 Android 的个人记账应用。

Summa 不要求登录，不依赖后台服务器。账户、负债、分类和账单默认只
保存在设备上的 SQLite 数据库中，并可随时导出为人类可读格式或完整备份。

> 当前稳定版本：[`v0.4.1`](https://github.com/ManiaAmaeOvo/Summa/releases/tag/v0.4.1)
> （`0.4.1+5`）。项目处于早期公开测试阶段，建议在录入重要数据后定期导出完整备份。

## 为什么做 Summa

这个项目源于一个使用 Python、NumPy 和 Markdown 编写的个人记账工具。
旧版本依赖命令行或需要常驻 Server 的 Web UI，因此无法真正做到随身、离线、
开箱即用。Summa 使用 Flutter 从头构建，先完成 Android 端，未来可以在
同一数据模型上扩展桌面端与 iOS。

项目早期开发阶段曾使用 `LedgerPro` 作为名称，现已更名为 `Summa`。为保证
已安装测试版本和既有备份可以继续升级与恢复，部分不会展示给用户的内部标识
仍保留旧名称。

## 已实现功能

- 支出、收入、借入、还款和个人账户间转账。
- 支出与收入各自独立的两级分类，可新增、重命名、排序和停用，“其他”始终置底。
- 现金、银行卡、电子钱包、受托/授权资金和负债账户。
- 余额不足、超额还款等硬性校验，避免账户出现不合理负数。
- 日报、周报、月报和年报，以及收支分类饼图和带标尺的收支/负债趋势图。
- 严格 JSON 单笔/批量导入，复制模板自带 LLM 提示，导入前可逐条预览和编辑。
- JSON 中不存在的账户可在确认后随批次原子创建。
- 按时间范围导出 JSON、CSV 或 Markdown 账单。
- 完整备份与覆盖/合并恢复；恢复前自动保存当前账本。
- 每次启动后的第一次有效修改前自动备份，滚动保留最近 5 个节点。
- 手动本地备份节点可查看、重命名、删除、合并或直接回档。
- 可选择仅重置账单与账户，或将数据和本地备份一并恢复出厂。
- 全部核心功能可以脱机使用。
- 完整英文与简体中文界面，可跟随系统或在设置中手动切换。
- 未经改名的默认账户和分类会随语言显示，自定义名称保持原样。
- 字体大小可跟随 Android 系统，也可为 Summa 单独选择小、标准、大或特大。

## 安装

从项目 Release 页面下载 APK，在 Android 设备上允许“安装未知应用”后安装。

开发构建也可以通过 Flutter 直接安装：

```bash
flutter pub get
flutter run
```

当前 Android 要求 `minSdk 24`，目标 SDK 为 36。

## 快速使用

1. 在底部“账户”中校准现金、银行卡、钱包和负债的当前余额。
2. 点击首页“记一笔”，选择支出、收入、借入、还款或转账并保存。
3. 在“设置 → 分类管理”维护收入和支出的两级分类。
4. 首页右上角代码图标可粘贴严格 JSON，预览并批量导入账单。
5. “报表”提供日/周/月/年汇总，并可按范围导出 JSON、CSV 或 Markdown。
6. “设置 → 数据与备份”可管理自动/手动本地节点、外部备份、回档与重置。
7. “设置 → 语言”可选择跟随系统、English 或简体中文。
8. “设置 → 字体大小”可调整软件内文字；点击首页“流动净资产”可直接进入账户页。

详细操作、账本含义、JSON 示例、备份区别和常见问题见
[Summa 完整使用说明](USER_GUIDE.zh-CN.md)。应用内也可打开“设置 → 使用说明”离线阅读。

## JSON 导入示例

```json
{
  "schema_version": 1,
  "transactions": [
    {
      "type": "expense",
      "amount": "28.50",
      "occurred_at": "2026-09-09T12:30:00+08:00",
      "category": "饮食/午餐",
      "account": "支付宝",
      "account_kind": "wallet",
      "note": "午餐"
    },
    {
      "type": "transfer",
      "amount": "100.00",
      "occurred_at": "2026-09-09T18:00:00+08:00",
      "account": "支付宝",
      "target_account": "微信",
      "note": "余额转移"
    }
  ]
}
```

完整字段与推断规则见 [JSON 导入协议](docs/zh-CN/json-import.md)。日常使用建议先阅读
[完整使用说明](USER_GUIDE.zh-CN.md)。

## 技术栈

- Flutter / Dart
- Material 3
- Riverpod
- Drift + SQLite
- `share_plus`、`file_picker` 与 `package_info_plus`

架构说明见 [docs/architecture.md](docs/zh-CN/architecture.md)，账本规则及产品决策见
[docs/product-foundation.md](docs/zh-CN/product-foundation.md)。

## 本地开发

环境准备、模拟器和构建命令见 [开发与发布指南](docs/zh-CN/development.md)。常用检查：

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release
```

## 数据与隐私

- Summa 当前不包含统计 SDK、广告 SDK 或远程账户系统。
- 应用不会主动上传账本；分享或导出文件只在用户明确操作后发生。
- 卸载应用通常会删除 Android 应用私有目录，请先导出完整备份。
- 完整备份包含敏感财务信息，应保存在可信位置。
- 自动和手动本地节点位于应用专属文档目录的 `summa_backups` 下，实际路径会
  显示在“设置 → 数据与备份”。新版 Android 的普通文件管理器可能不允许直接
  浏览该目录；本地节点会随卸载或恢复出厂而删除，长期留存请使用导出功能。

## 项目状态与路线

- 真机反馈与无障碍/小屏适配。
- 分类导入映射和更友好的批量纠错。
- 可选 OCR 与自然语言账单解析，但模型输出仍须经过本地校验和确认。
- 桌面端管理界面与 iOS 适配。

版本变化见 [CHANGELOG.md](CHANGELOG.zh-CN.md)。

## 参与贡献

欢迎提交问题、改进建议和 Pull Request。开始前请阅读
[CONTRIBUTING.md](CONTRIBUTING.zh-CN.md) 与 [SECURITY.md](SECURITY.zh-CN.md)。

## 许可证

Summa 源码公开，并采用
[PolyForm Noncommercial License 1.0.0](LICENSE) 授权。你可以在非商业目的下
使用、研究、修改和再分发本软件；获得软件副本的人也必须同时获得许可证以及
项目提供的署名声明。任何商业用途均不在此许可证授权范围内。

这是一份非商业的源码可用许可证，并非 OSI 认证的开源许可证。具体权利和
限制以英文 `LICENSE` 正文为准，作者与项目来源见 [NOTICE](NOTICE)。

## 致谢

Summa 由 [ManiaAmaeOvo](https://github.com/ManiaAmaeOvo) 发起并维护，
使用 OpenAI Codex 协作构建。
