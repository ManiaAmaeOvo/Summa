# JSON 导入协议

**简体中文** | [English](../json-import.md)

Summa 接受单个交易对象、交易数组或带 `schema_version` 的标准包装对象。
界面会先解析并展示预览，只有用户确认后才会以单一事务写入数据库。

## 通用字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `type` | string | `expense`、`income`、`transfer`、`borrowing` 或 `repayment` |
| `amount` | string | 正数十进制人民币金额，最多两位小数 |
| `occurred_at` | string | ISO 8601 时间，建议携带时区偏移 |
| `account` | string | 来源/记账账户名称 |
| `account_kind` | string? | 新账户类型，可省略 |
| `target_account` | string? | 转账、借入与还款必填 |
| `target_account_kind` | string? | 新目标账户类型，可省略 |
| `category` | string? | 支出与收入必填，格式为 `一级/二级` |
| `note` | string? | 最多 200 字 |

账户类型可选值为 `cash`、`bank`、`wallet`、`creditLine` 和
`entrustedFunds`。普通未知账户默认推断为 `wallet`；借入来源和还款目标
推断为 `creditLine`。

未知账户会在预览中标记为“将新建”。同一批次内同名未知账户只创建一次。
新账户与账单处于同一事务，任意一条失败都不会留下孤立账户。

未知分类不会静默创建，以防 OCR 或语言模型的错别字污染分类列表。请先在
分类管理中建立分类，或在预览前修改生成的 JSON。

## 交易流向

- `expense`：从 `account` 支出。
- `income`：收入进入 `account`；若账户是负债，则表示冲减负债。
- `transfer`：个人余额账户 `account` 转入 `target_account`。
- `borrowing`：负债账户 `account` 增加，同时资金进入个人余额目标账户。
- `repayment`：个人余额账户 `account` 支付，目标负债账户减少。
