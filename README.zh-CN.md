# Summa

**简体中文** | [English](README.md)

一款完全本地优先、面向 Android 的个人记账应用。

Summa 不要求登录，不依赖后台服务器。账户、负债、分类和账单默认只
保存在设备上的 SQLite 数据库中，并可随时导出为人类可读格式或完整备份。

> 旧版迁移基线为 [`v0.4.2`](https://github.com/ManiaAmaeOvo/Summa/releases/tag/v0.4.2)
> （`0.4.2+6`）。当前分支对应 Summa 2.0 及后续开发版。

## 为什么做 Summa

这个项目源于一个使用 Python、NumPy 和 Markdown 编写的个人记账工具。
旧版本依赖命令行或需要常驻 Server 的 Web UI，因此无法真正做到随身、离线、
开箱即用。Summa 使用 Flutter 从头构建，先完成 Android 端，未来可以在
同一数据模型上扩展桌面端与 iOS。

Summa 2.0 开发版使用 Android 应用 ID `com.maniaamae.summa`，可与 v0.4.2
及更早版本并存。迁移账本时，请先在旧版的「设置 → 数据与备份」导出完整
JSON 备份，再在新版的同一页面恢复。核对账户余额和交易记录后，再卸载旧版。

## 已实现功能

- 多币种账户、拆分支付、部分退款、待入账、结算与估值汇率。
- 区分本人承担、家庭直接承担和受托付款，支持垫付及应收回款。
- 预算、按月重置的亲情卡额度、周期收支和订阅、债务与应收合同、储蓄目标。
- 通用 CSV、微信和支付宝账单导入，支持分类规则试跑、人工复核与批次撤销。
- 代码块 JSON 导入支持 OCR / LLM 模板和逐条复核。
- 账户对账、现金流预测、多维报告和历史分析。报告支持 JSON、CSV、XLSX、Markdown。
- 完整备份和覆盖／合并恢复，支持旧版备份。
- 核心功能离线可用，支持简体中文、英文、深色模式和字体大小设置。

## 安装

从项目 Release 页面下载 APK，在 Android 设备上允许“安装未知应用”后安装。

开发构建也可以通过 Flutter 直接安装：

```bash
flutter pub get
flutter run
```

当前 Android 要求 `minSdk 24`，目标 SDK 为 36。

## 快速使用

1. 在「账户」核对各币种余额。亲情卡可在账户菜单设定「周期重置额度」。
2. 从首页「记一笔」，或从「账单」导入文件／JSON 后复核。
3. 在「规划」管理预算和计划，在「报表」核对消费、本人承担和现金流。
4. 在「设置 → 数据与备份」保存一份外部完整 JSON。

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
