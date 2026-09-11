// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Summa';

  @override
  String get settings => '设置';

  @override
  String get ledger => '账本';

  @override
  String get app => '应用';

  @override
  String get categoryManagement => '分类管理';

  @override
  String get categoryManagementSubtitle => '维护收入和支出的两级分类';

  @override
  String get dataAndBackup => '数据与备份';

  @override
  String get dataAndBackupSubtitle => '本地节点、导出、恢复与重置';

  @override
  String get language => '语言';

  @override
  String get languageSubtitle => '选择 Summa 使用的界面语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSimplifiedChinese => '简体中文';

  @override
  String get fontSize => '字体大小';

  @override
  String get fontSizeSubtitle => '调整 Summa 全局文字大小';

  @override
  String get fontSizeSystem => '跟随系统';

  @override
  String get fontSizeSmall => '小';

  @override
  String get fontSizeStandard => '标准';

  @override
  String get fontSizeLarge => '大';

  @override
  String get fontSizeExtraLarge => '特大';

  @override
  String get userGuide => '使用说明';

  @override
  String get userGuideSubtitle => '功能介绍、操作方法与数据安全';

  @override
  String get aboutSumma => '关于 Summa';

  @override
  String get aboutSummaSubtitle => '版本、简介与开发者信息';

  @override
  String versionLabel(String version, String buildNumber) {
    return '版本 $version（$buildNumber）';
  }

  @override
  String get readingVersion => '正在读取版本信息…';

  @override
  String get aboutDescription =>
      '一款完全本地优先的个人记账工具。账户、负债、分类和账单默认只保存在你的设备上，无需登录，也不依赖后台服务器。';

  @override
  String get developer => '开发者';

  @override
  String get builtWith => '协作构建';

  @override
  String get dataPrinciples => '数据原则';

  @override
  String get dataPrinciplesValue => '本地存储、明确导出、由用户掌控';

  @override
  String get softwareLicense => '软件许可';

  @override
  String get softwareLicenseValue => 'PolyForm Noncommercial 1.0.0 · 仅限非商业用途';

  @override
  String get cannotOpenGitHub => '无法打开 GitHub 主页';

  @override
  String get helpIntro => 'Summa 完全本地运行。建议先校准账户余额，再检查分类并开始记账；重要数据请定期导出完整备份。';

  @override
  String get helpTransactionsTitle => '记账与交易类型';

  @override
  String get helpTransactions1 =>
      '首页点击“记一笔”，可记录支出、收入、借入、还款和个人账户转账。日期默认使用当前时间，也可手动修改。';

  @override
  String get helpTransactions2 =>
      '借入会同时增加负债和目标账户余额，不算收入；还款同时减少付款余额和负债，不算支出；转账不进入收支统计。';

  @override
  String get helpTransactions3 => '余额不足、超额还款或无效账户流向会被拒绝。点击已有账单可以编辑或软删除。';

  @override
  String get helpAccountsTitle => '账户与分类';

  @override
  String get helpAccounts1 =>
      '底部“账户”展示个人流动资产、待偿负债、流动净资产和受托/授权资金。点击账户可校准当前余额；校准不会产生虚假收入或支出。';

  @override
  String get helpAccounts2 =>
      '账户可新增或停用。设置中的分类管理分别维护收入和支出的两级分类；账单实际选择二级分类，每个一级分类保留“其他”兜底项。';

  @override
  String get helpJsonTitle => 'JSON 代码块导入';

  @override
  String get helpJson1 => '首页右上角代码图标可粘贴单笔或批量 JSON，适合把账单截图经 OCR 或语言模型整理后导入。';

  @override
  String get helpJson2 =>
      '流程为解析校验、逐条预览和编辑、确认数量、原子写入。未知账户可自动创建，未知分类需要先创建或在预览中修正。';

  @override
  String get helpJson3 => '金额使用正数十进制字符串，时间使用 ISO 8601，分类写作“一级/二级”。';

  @override
  String get helpReportsTitle => '报表与导出';

  @override
  String get helpReports1 => '底部“报表”支持日报、周报、月报和年报，并展示收支分类饼图、支出趋势和负债走势。';

  @override
  String get helpReports2 =>
      '账单可按本周、本月、本年、全部或自选时间段导出为 JSON、CSV 或 Markdown。账单导出用于分析，不等同于可还原整个软件的完整备份。';

  @override
  String get helpBackupTitle => '备份、合并与回档';

  @override
  String get helpBackup1 => '每次启动后的第一次成功修改前自动保存完整状态，最多保留最近 5 个节点；失败操作不会占用节点。';

  @override
  String get helpBackup2 =>
      '手动备份可保存为软件内节点或导出到外部。点击本地节点可预览并覆盖回档，菜单中还可合并、重命名手动节点或删除。';

  @override
  String get helpBackup3 => '软件内节点位于设置页所示的应用专属目录，会随卸载或恢复出厂而删除；长期保存请选择导出或分享。';

  @override
  String get helpResetTitle => '重置范围';

  @override
  String get helpReset1 => '“重置账单与账户”清空账单和自定义账户，将默认账户归零，但保留分类和备份。';

  @override
  String get helpReset2 => '“恢复出厂设置”还会恢复默认分类并删除全部软件内备份。外部导出的文件不受影响。';

  @override
  String get helpSecurityTitle => '数据安全';

  @override
  String get helpSecurity1 => '账本默认仅保存在设备上。卸载通常会删除数据库和本地节点，换机或卸载前必须导出完整备份。';

  @override
  String get helpSecurity2 => '完整备份包含敏感财务信息，请只保存到可信位置，不要把真实备份上传到公开 Issue。';

  @override
  String get accountBalances => '账户余额';

  @override
  String get reports => '报表';

  @override
  String get codeImport => '代码块导入';

  @override
  String get addTransaction => '记一笔';

  @override
  String get transactions => '账单';

  @override
  String get accounts => '账户';

  @override
  String get expenseThisMonth => '本月支出';

  @override
  String get expenseThisWeek => '本周支出';

  @override
  String get expenseAllTime => '累计支出';

  @override
  String get liquidNetWorth => '流动净资产';

  @override
  String get transactionActions => '账单操作';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get cancel => '取消';

  @override
  String get confirmDeleteTransaction => '删除这笔记录？';

  @override
  String get deleteRecalculatesBalances => '删除后相关账户余额会自动回算。';

  @override
  String get transactionDeleted => '记录已删除';

  @override
  String get deleteFailed => '删除失败，请重试';

  @override
  String get expense => '支出';

  @override
  String get income => '收入';

  @override
  String get borrowing => '借入';

  @override
  String get repayment => '还款';

  @override
  String get transfer => '转账';

  @override
  String creditedTo(String account) {
    return '计入 $account';
  }

  @override
  String get noTransactions => '还没有账单';

  @override
  String get noTransactionsHint => '点击“记一笔”，添加第一条本地记录。';

  @override
  String get ledgerReadFailed => '账本读取失败';

  @override
  String get retry => '重试';

  @override
  String get accountBalanceReadFailed => '账户余额读取失败';

  @override
  String archiveAccountTitle(String account) {
    return '停用$account？';
  }

  @override
  String get archiveAccountDescription =>
      '账户会从可选列表和余额汇总中移除，但历史账单仍会保留。默认账户之后可以通过“恢复默认”重新启用。';

  @override
  String get archive => '停用';

  @override
  String accountArchived(String account) {
    return '$account已停用';
  }

  @override
  String get archiveFailed => '停用失败，请重试';

  @override
  String get defaultAccountsRestored => '默认账户已恢复，原有余额没有被重置';

  @override
  String get restoreFailed => '恢复失败，请重试';

  @override
  String get personalLiquidAssets => '个人流动资产';

  @override
  String get outstandingLiabilities => '待偿负债';

  @override
  String get entrustedFunds => '受托/授权资金';

  @override
  String get addAccount => '添加账户';

  @override
  String get restoreDefaults => '恢复默认';

  @override
  String get personalAccounts => '个人账户';

  @override
  String get personalAccountsDescription => '属于你的现金、银行卡与钱包余额';

  @override
  String get entrustedFundsDescription => '可以使用，但不计入个人资产';

  @override
  String get liabilityAccounts => '负债账户';

  @override
  String get liabilityAccountsDescription => '显示当前应偿还金额';

  @override
  String get accountCalibrationHint => '点击账户可校准当前余额。之后的支出会从资产账户扣除，或增加负债账户欠款。';

  @override
  String get addAccountOrLiability => '添加账户或负债';

  @override
  String get name => '名称';

  @override
  String get liabilityNameExample => '例如：朋友欠款';

  @override
  String get assetNameExample => '例如：储蓄卡';

  @override
  String get accountingType => '核算类型';

  @override
  String get currentAmountOwed => '当前待偿金额';

  @override
  String get currentBalance => '当前余额';

  @override
  String get zeroThenCalibrate => '可先填 0，之后随时校准';

  @override
  String get adding => '添加中…';

  @override
  String get add => '添加';

  @override
  String get enterName => '请输入名称';

  @override
  String get nameAlreadyExists => '这个名称已经存在';

  @override
  String get addFailed => '添加失败，请重试';

  @override
  String get accountKindCash => '现金';

  @override
  String get accountKindBank => '银行卡';

  @override
  String get accountKindWallet => '支付钱包';

  @override
  String get accountKindEntrustedFunds => '受托/授权资金';

  @override
  String get accountKindLiability => '负债账户';

  @override
  String calibrateLiability(String account) {
    return '校准$account当前负债';
  }

  @override
  String calibrateBalance(String account) {
    return '校准$account当前余额';
  }

  @override
  String get nonNegativeTwoDecimals => '不能为负数，最多两位小数';

  @override
  String get saving => '保存中…';

  @override
  String get save => '保存';

  @override
  String get saveFailed => '保存失败，请重试';

  @override
  String get liability => '负债';

  @override
  String get balance => '余额';

  @override
  String get accountActions => '账户操作';

  @override
  String get archiveAccount => '停用账户';

  @override
  String get moneyInvalidFormat => '请输入正确金额，最多保留两位小数';

  @override
  String get moneyNotNegative => '金额不能小于 0';

  @override
  String get moneyGreaterThanZero => '金额必须大于 0';

  @override
  String get restoreDefaultCategories => '恢复默认分类';

  @override
  String get restoreDefaultCategoriesTitle => '恢复默认分类？';

  @override
  String get restoreDefaultCategoriesDescription =>
      '只会重新启用缺失的默认分类，不会删除或重置自定义分类。';

  @override
  String get restore => '恢复';

  @override
  String get defaultCategoriesRestored => '默认分类已恢复，自定义分类未受影响';

  @override
  String get categoryReadFailed => '分类读取失败';

  @override
  String get categoryStructureHint => '一级分类用于汇总，二级分类用于每笔账单。历史账单会保留已停用分类的名称。';

  @override
  String get addPrimaryCategory => '添加一级分类';

  @override
  String secondaryCategoryCount(int count) {
    return '$count 个二级分类';
  }

  @override
  String get rename => '重命名';

  @override
  String get moveUp => '向上移动';

  @override
  String get moveDown => '向下移动';

  @override
  String get archiveCategory => '停用分类';

  @override
  String get addSecondaryCategory => '添加二级分类';

  @override
  String addToCategory(String category) {
    return '添加到“$category”';
  }

  @override
  String get renamePrimaryCategory => '重命名一级分类';

  @override
  String get renameSecondaryCategory => '重命名二级分类';

  @override
  String archiveCategoryTitle(String category) {
    return '停用“$category”？';
  }

  @override
  String get archivePrimaryCategoryDescription =>
      '该一级分类及其二级分类将不再用于新账单，历史账单不受影响。';

  @override
  String get archiveSecondaryCategoryDescription => '该分类将不再用于新账单，历史账单不受影响。';

  @override
  String get categoryName => '分类名称';

  @override
  String get categoryNameNoSlash => '名称不能包含 /';

  @override
  String get categoryNameInvalidOrDuplicate => '名称无效或同级分类已存在';

  @override
  String get calibrateBalanceAction => '校准余额';

  @override
  String insufficientBalance(String account, String amount) {
    return '$account余额不足，当前可用 $amount';
  }

  @override
  String overpayment(String account, String amount) {
    return '$account待偿负债仅 $amount，不能超额冲减';
  }

  @override
  String get fixedOtherCategory => '“其他”是该主分类的固定兜底项';

  @override
  String get otherCategoryRequired => '每个主分类必须保留“其他”子分类';

  @override
  String get editTransaction => '编辑记录';

  @override
  String get close => '关闭';

  @override
  String get amount => '金额';

  @override
  String get categoryLoadFailed => '分类加载失败';

  @override
  String get accountLoadFailed => '账户加载失败';

  @override
  String get noteOptional => '备注（可选）';

  @override
  String get saveChanges => '保存修改';

  @override
  String get saveTransaction => '保存记录';

  @override
  String get expenseNoteHint => '这笔钱花在了哪里？';

  @override
  String get incomeNoteHint => '这笔钱来自哪里？';

  @override
  String get transferNoteHint => '例如：支付宝转入微信';

  @override
  String get borrowingNoteHint => '例如：向朋友借款';

  @override
  String get repaymentNoteHint => '例如：归还朋友欠款';

  @override
  String get primaryCategory => '主分类';

  @override
  String get secondaryCategory => '子分类';

  @override
  String get paymentAccount => '付款账户';

  @override
  String get incomeDestinationAccount => '收入计入账户';

  @override
  String archivedName(String name) {
    return '$name（已停用）';
  }

  @override
  String get quickAddLiability => '快捷添加负债账户';

  @override
  String get fundsDestinationAccount => '资金存入账户';

  @override
  String get repaymentSourceAccount => '还款账户';

  @override
  String get repaymentLiabilityAccount => '偿还负债账户';

  @override
  String get transferFromAccount => '转出账户';

  @override
  String get transferToAccount => '转入账户';

  @override
  String get addAvailableAccountFirst => '请先添加可用账户';

  @override
  String liabilityName(String name) {
    return '$name（负债）';
  }

  @override
  String get selectRequiredAccountAndCategory => '请先选择所需账户和分类';

  @override
  String get transactionChangesSaved => '记录修改已保存';

  @override
  String get transactionSavedLocally => '记录已保存到本地';

  @override
  String get saveLaterFailed => '保存失败，请稍后重试';

  @override
  String confirmImportCount(int count) {
    return '是否导入 $count 条账单？';
  }

  @override
  String get jsonImportInstructions =>
      '粘贴单笔、数组或 schema_version 1 批量 JSON。金额必须是字符串，分类使用“主分类/子分类”。';

  @override
  String get jsonCode => 'JSON 代码块';

  @override
  String get importTemplateCopied => '导入模板已复制';

  @override
  String get copyTemplate => '复制模板';

  @override
  String get parseAndPreview => '解析并预览';

  @override
  String get loading => '正在加载…';

  @override
  String willCreateAccount(String kind, String name) {
    return '将新建$kind账户：$name';
  }

  @override
  String get removeItem => '移除此条';

  @override
  String get backToCode => '返回修改代码';

  @override
  String get importing => '导入中…';

  @override
  String confirmImportButton(int count) {
    return '确认导入 $count 条';
  }

  @override
  String importedCount(int count) {
    return '已导入 $count 条账单';
  }

  @override
  String batchNotImportedReason(String reason) {
    return '整批未导入：$reason';
  }

  @override
  String get batchNotImported => '整批未导入，请检查内容后重试';

  @override
  String editTypedTransaction(String type) {
    return '编辑$type记录';
  }

  @override
  String get isoTimestamp => 'ISO 8601 时间';

  @override
  String get account => '账户';

  @override
  String get targetAccount => '目标账户';

  @override
  String get category => '分类';

  @override
  String get note => '备注';

  @override
  String get invalidTimestamp => '时间格式不正确';

  @override
  String get accountKindElectronicWallet => '电子钱包';

  @override
  String get accountKindEntrustedShort => '委托/授权资金';

  @override
  String get reportReadFailed => '报表读取失败';

  @override
  String get periodDay => '日';

  @override
  String get periodWeek => '周';

  @override
  String get periodMonth => '月';

  @override
  String get periodYear => '年';

  @override
  String get expenseCategories => '支出分类';

  @override
  String get noExpenseCategoryData => '此周期暂无支出分类数据';

  @override
  String get incomeCategories => '收入分类';

  @override
  String get noIncomeCategoryData => '此周期暂无收入分类数据';

  @override
  String get exportTransactions => '导出账单';

  @override
  String get incomeExpenseBalance => '收支结余';

  @override
  String get borrowingRepayment => '借入 / 还款';

  @override
  String get expenseTrend => '支出趋势';

  @override
  String get noExpensesThisPeriod => '此周期暂无支出';

  @override
  String get liabilityTrend => '负债走势';

  @override
  String closingAmount(String amount) {
    return '期末 $amount';
  }

  @override
  String get noLiabilityData => '暂无负债账户或负债变动';

  @override
  String liabilityRangeSummary(String opening, String current) {
    return '期初 $opening · 当前总负债 $current';
  }

  @override
  String get timeRange => '时间范围';

  @override
  String get thisWeek => '本周';

  @override
  String get thisMonth => '本月';

  @override
  String get thisYear => '本年';

  @override
  String get allTime => '全部';

  @override
  String get customRange => '自定义时间段';

  @override
  String get fileFormat => '文件格式';

  @override
  String get jsonFormatDescription => 'JSON（完整、可重新导入）';

  @override
  String get csvFormatDescription => 'CSV（表格分析）';

  @override
  String get markdownFormatDescription => 'Markdown（阅读）';

  @override
  String get preparing => '准备中…';

  @override
  String get export => '导出';

  @override
  String get transactionExportSubject => 'Summa 账单导出';

  @override
  String get backupUnderYourControl => '完整备份由你掌控';

  @override
  String get backupLocationDescription =>
      '本地节点保存在 Summa 的应用专属文档目录；新版 Android 的普通文件管理器可能不会直接显示该目录，请在本页管理或导出。';

  @override
  String get automaticBackups => '自动备份';

  @override
  String get automaticBackupsSubtitle => '每次启动后的第一次成功修改前保存，滚动保留最近 5 个节点。';

  @override
  String get noAutomaticBackupYet => '本次启动尚未发生有效修改';

  @override
  String get manualBackups => '手动备份';

  @override
  String get manualBackupsSubtitle => '本地节点留在应用中；导出分享可保存到文件管理器、云盘或其他位置。';

  @override
  String get backupInsideApp => '备份到软件本地';

  @override
  String get backupInsideAppSubtitle => '创建一个不受 5 个自动节点限制的手动节点';

  @override
  String get exportOrShareBackup => '导出或分享备份';

  @override
  String get exportOrShareBackupSubtitle => '生成 Summa 完整 JSON 备份并交给系统保存';

  @override
  String get restoreExternalBackup => '从外部备份文件恢复';

  @override
  String get restoreExternalBackupSubtitle => '选择 JSON 文件后覆盖回档或合并';

  @override
  String get noManualBackups => '还没有手动本地备份';

  @override
  String get reset => '重置';

  @override
  String get resetSubtitle => '重置账本会保留本地备份，恢复出厂会同时删除它们。';

  @override
  String get resetTransactionsAccounts => '重置账单与账户';

  @override
  String get resetTransactionsAccountsSubtitle => '清空账单，账户恢复默认且余额归零；保留分类和备份';

  @override
  String get factoryReset => '恢复出厂设置';

  @override
  String get factoryResetSubtitle => '清空账单、账户、分类以及所有本地备份';

  @override
  String get cannotReadBackupDirectory => '无法读取本地备份目录';

  @override
  String get manualBackupName => '手动备份名称';

  @override
  String get myBackup => '我的备份';

  @override
  String get manualBackupSaved => '手动备份已保存到软件本地';

  @override
  String get createLocalBackupFailed => '创建本地备份失败';

  @override
  String get completeBackupSubject => 'Summa 完整备份';

  @override
  String get backupExportFailed => '备份导出失败，请重试';

  @override
  String get cannotReadSelectedBackup => '无法读取所选备份文件';

  @override
  String get renameBackup => '重命名备份';

  @override
  String get renameBackupFailed => '重命名失败，请检查是否存在同名备份';

  @override
  String get deleteBackupTitle => '删除备份节点？';

  @override
  String deleteBackupMessage(String name) {
    return '“$name”将被永久删除，无法撤销。';
  }

  @override
  String get deleteBackupFailed => '删除备份失败';

  @override
  String get backupNoLongerAvailable => '备份节点已不存在或无法读取';

  @override
  String get restoredSelectedBackup => '已回档到所选备份';

  @override
  String get backupMerged => '备份已合并';

  @override
  String get restoreDatabaseSafeFailure => '恢复失败，数据库没有被部分修改';

  @override
  String get confirmRestoreContents => '确认恢复内容';

  @override
  String get merge => '合并';

  @override
  String get replaceAndRestore => '覆盖回档';

  @override
  String get restoreThisSnapshotTitle => '回档到此节点？';

  @override
  String get mergeThisSnapshotTitle => '合并此节点？';

  @override
  String get confirmRestore => '确认回档';

  @override
  String get confirmMerge => '确认合并';

  @override
  String get resetTransactionsAccountsTitle => '重置账单与账户？';

  @override
  String get resetTransactionsAccountsMessage =>
      '全部账单将被永久清除，自定义账户将删除，默认账户余额归零。分类和所有备份会保留。';

  @override
  String get confirmReset => '确认重置';

  @override
  String get transactionsAccountsReset => '账单与账户已重置，备份均已保留';

  @override
  String get resetSafeFailure => '重置失败，数据没有被部分修改';

  @override
  String get factoryResetTitle => '恢复出厂设置？';

  @override
  String get factoryResetMessage => '账单、账户、分类和软件内全部备份都将永久清除。导出到应用外部的文件不受影响。';

  @override
  String get clearEverything => '全部清除';

  @override
  String get factoryResetComplete => 'Summa 已恢复出厂设置';

  @override
  String get factoryResetFailed => '恢复出厂设置失败';

  @override
  String get tapToRestore => '点击回档';

  @override
  String get mergeIntoLedger => '合并到当前账本';

  @override
  String backupTime(String time) {
    return '备份时间：$time';
  }

  @override
  String backupAccountCount(int count) {
    return '账户：$count';
  }

  @override
  String backupCategoryCount(int count) {
    return '分类：$count';
  }

  @override
  String backupTransactionCount(int count, int deleted) {
    return '账单：$count（含 $deleted 条已删除记录）';
  }

  @override
  String get restoreSafetyHint => '执行成功前，Summa 会按本次启动的自动备份规则保护当前状态。';

  @override
  String get automaticBackupName => '自动备份';

  @override
  String backupInvalidJson(String details) {
    return '备份 JSON 格式错误：$details';
  }

  @override
  String get backupUnsupported => '这不是受支持的 Summa 完整备份';

  @override
  String get backupInvalidTime => '备份时间无效';

  @override
  String backupMissingList(String field) {
    return '备份缺少 $field 列表';
  }

  @override
  String backupInvalidItem(String field) {
    return '$field 中包含无效项目';
  }

  @override
  String backupFieldMustString(String field) {
    return '字段 $field 必须是字符串';
  }

  @override
  String backupFieldMustNullableString(String field) {
    return '字段 $field 必须是字符串或 null';
  }

  @override
  String backupFieldMustInteger(String field) {
    return '字段 $field 必须是整数';
  }

  @override
  String backupFieldMustBoolean(String field) {
    return '字段 $field 必须是布尔值';
  }

  @override
  String backupFieldInvalidTime(String field) {
    return '字段 $field 不是有效时间';
  }

  @override
  String backupFieldUnsupportedValue(String field, String value) {
    return '字段 $field 的值不受支持：$value';
  }
}
