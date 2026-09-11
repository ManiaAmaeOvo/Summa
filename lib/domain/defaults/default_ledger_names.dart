import 'package:ledger_pro/domain/accounts/ledger_account.dart';
import 'package:ledger_pro/domain/categories/ledger_category.dart';

class DefaultLedgerNames {
  const DefaultLedgerNames._();

  static const accounts = <String, ({String en, String zh})>{
    'account-cash': (en: 'Cash', zh: '现金'),
    'account-bank': (en: 'Bank Account', zh: '银行卡'),
    'account-alipay': (en: 'Alipay', zh: '支付宝'),
    'account-wechat': (en: 'WeChat Pay', zh: '微信'),
    'account-huabei': (en: 'Huabei', zh: '花呗'),
    'account-jd-baitiao': (en: 'JD Baitiao', zh: '白条'),
    'account-douyin-pay': (en: 'Douyin Monthly Pay', zh: '抖音月付'),
    'account-meituan-pay': (en: 'Meituan Monthly Pay', zh: '美团月付'),
    'account-family-card': (en: 'Family Card', zh: '亲情卡'),
  };

  static const categories = <String, ({String en, String zh})>{
    'expense-parent-0': (en: 'Food', zh: '饮食'),
    'expense-parent-0-child-0': (en: 'Breakfast', zh: '早餐'),
    'expense-parent-0-child-1': (en: 'Lunch', zh: '午餐'),
    'expense-parent-0-child-2': (en: 'Dinner', zh: '晚餐'),
    'expense-parent-0-child-3': (en: 'Snacks & Drinks', zh: '零食饮料'),
    'expense-parent-0-child-4': (en: 'Groceries', zh: '食材'),
    'expense-parent-0-child-5': (en: 'Other', zh: '其他'),
    'expense-parent-1': (en: 'Transport', zh: '交通'),
    'expense-parent-1-child-0': (en: 'Bus & Metro', zh: '公交地铁'),
    'expense-parent-1-child-1': (en: 'Ride-hailing', zh: '网约车'),
    'expense-parent-1-child-2': (en: 'Cycling', zh: '骑行'),
    'expense-parent-1-child-3': (en: 'Long-distance Travel', zh: '长途交通'),
    'expense-parent-1-child-4': (en: 'Other', zh: '其他'),
    'expense-parent-2': (en: 'Daily Needs', zh: '日用'),
    'expense-parent-2-child-0': (en: 'Household Supplies', zh: '生活用品'),
    'expense-parent-2-child-1': (en: 'Clothing', zh: '衣物'),
    'expense-parent-2-child-2': (en: 'Electronics', zh: '数码'),
    'expense-parent-2-child-3': (en: 'Healthcare', zh: '医疗健康'),
    'expense-parent-2-child-4': (en: 'Other', zh: '其他'),
    'expense-parent-3': (en: 'Entertainment', zh: '娱乐'),
    'expense-parent-3-child-0': (en: 'Games', zh: '游戏'),
    'expense-parent-3-child-1': (en: 'Movies & Music', zh: '影音'),
    'expense-parent-3-child-2': (en: 'Social', zh: '社交'),
    'expense-parent-3-child-3': (en: 'Travel', zh: '旅行'),
    'expense-parent-3-child-4': (en: 'Other', zh: '其他'),
    'expense-parent-4': (en: 'Other', zh: '其他'),
    'expense-parent-4-child-0': (en: 'Uncategorized', zh: '未分类'),
    'income-parent-0': (en: 'Earned Income', zh: '劳动所得'),
    'income-parent-0-child-0': (en: 'Salary', zh: '工资'),
    'income-parent-0-child-1': (en: 'Side Job', zh: '兼职'),
    'income-parent-0-child-2': (en: 'Other', zh: '其他'),
    'income-parent-1': (en: 'Family Support', zh: '家庭支持'),
    'income-parent-1-child-0': (en: 'Living Allowance', zh: '生活费'),
    'income-parent-1-child-1': (en: 'Family Gift', zh: '亲属赠予'),
    'income-parent-1-child-2': (en: 'Purchase Remainder', zh: '采购结余'),
    'income-parent-1-child-3': (en: 'Other', zh: '其他'),
    'income-parent-2': (en: 'Refunds & Reimbursements', zh: '退款报销'),
    'income-parent-2-child-0': (en: 'Refund', zh: '退款'),
    'income-parent-2-child-1': (en: 'Reimbursement', zh: '报销'),
    'income-parent-2-child-2': (en: 'Other', zh: '其他'),
    'income-parent-3': (en: 'Other Income', zh: '其他收入'),
    'income-parent-3-child-0': (en: 'Cash Gift', zh: '礼金'),
    'income-parent-3-child-1': (en: 'Investment Return', zh: '投资收益'),
    'income-parent-3-child-2': (en: 'Uncategorized', zh: '未分类'),
    'flow-borrowing-parent': (en: 'Borrowing', zh: '借入'),
    'flow-borrowing': (en: 'Borrowed Funds', zh: '借入资金'),
    'flow-repayment-parent': (en: 'Repayment', zh: '还款'),
    'flow-repayment': (en: 'Liability Repayment', zh: '偿还负债'),
    'flow-transfer-parent': (en: 'Transfer', zh: '转账'),
    'flow-transfer': (en: 'Account Transfer', zh: '账户间转账'),
  };

  static String accountName(
    String languageCode,
    String id,
    String storedName,
  ) => _localized(languageCode, storedName, accounts[id]);

  static String categoryName(
    String languageCode,
    String id,
    String storedName,
  ) => _localized(languageCode, storedName, categories[id]);

  static bool accountMatches(LedgerAccount account, String input) =>
      account.name == input ||
      _matches(accounts[account.id], account.name, input);

  static bool categoryMatches(LedgerCategory category, String input) =>
      category.name == input ||
      _matches(categories[category.id], category.name, input);

  static bool isOtherCategory(LedgerCategory category) =>
      category.name == '其他' ||
      category.name == 'Other' ||
      category.name == '其他收入' ||
      category.name == 'Other Income';

  static bool isProtectedOther(LedgerCategory category) =>
      category.parentId != null && isOtherCategory(category);

  static String _localized(
    String languageCode,
    String storedName,
    ({String en, String zh})? defaults,
  ) {
    if (defaults == null ||
        (storedName != defaults.en && storedName != defaults.zh)) {
      return storedName;
    }
    return languageCode == 'zh' ? defaults.zh : defaults.en;
  }

  static bool _matches(
    ({String en, String zh})? defaults,
    String storedName,
    String input,
  ) =>
      defaults != null &&
      (storedName == defaults.en || storedName == defaults.zh) &&
      (input == defaults.en || input == defaults.zh);
}
