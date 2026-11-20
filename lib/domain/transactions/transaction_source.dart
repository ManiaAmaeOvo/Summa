class TransactionSource {
  const TransactionSource({
    required this.batchId,
    required this.batchName,
    required this.line,
    required this.cells,
  });

  final String batchId;
  final String batchName;
  final int line;
  final Map<String, String> cells;

  String? get provider => _value(['source']);
  String? get channel =>
      _value(['payment_channel', '支付方式', '付款方式', '收/付款方式', '收付款方式']);
  String? get counterparty => _value(['counterparty', 'merchant', '交易对方']);

  String? _value(List<String> keys) {
    for (final key in keys) {
      final value = cells[key]?.trim();
      if (value != null && value.isNotEmpty && value != '/' && value != '-') {
        return value;
      }
    }
    return null;
  }
}
