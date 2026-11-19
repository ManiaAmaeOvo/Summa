import 'package:flutter/material.dart';
import 'package:summa/core/money/money.dart';

List<String> currencyOptions(Iterable<String> currencies) {
  final values = currencies.toSet().toList()..sort();
  if (values.isEmpty || values.remove(defaultCurrency)) {
    values.insert(0, defaultCurrency);
  }
  return values;
}

class CurrencySelector extends StatelessWidget {
  const CurrencySelector({
    super.key,
    required this.currencies,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final List<String> currencies;
  final String value;
  final String label;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(labelText: label),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        isDense: true,
        items: [
          for (final code in currencies)
            DropdownMenuItem(value: code, child: Text(code)),
        ],
        onChanged: onChanged == null
            ? null
            : (code) {
                if (code != null) onChanged!(code);
              },
      ),
    ),
  );
}
