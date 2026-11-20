import 'package:summa/core/money/money.dart';

enum ImportRuleField {
  merchant,
  description,
  paymentChannel,
  source,
  account,
  amount,
}

enum ImportRuleOperator { contains, equals, startsWith, atLeast, atMost }

enum ImportRuleMode { all, any }

class ImportRuleCondition {
  const ImportRuleCondition({
    required this.field,
    required this.operator,
    required this.value,
    this.currency,
  });

  final ImportRuleField field;
  final ImportRuleOperator operator;
  final String value;
  final String? currency;

  static List<ImportRuleOperator> operatorsFor(ImportRuleField field) =>
      field == ImportRuleField.amount
      ? const [
          ImportRuleOperator.equals,
          ImportRuleOperator.atLeast,
          ImportRuleOperator.atMost,
        ]
      : const [
          ImportRuleOperator.contains,
          ImportRuleOperator.equals,
          ImportRuleOperator.startsWith,
        ];

  bool get isValid {
    if (value.length > 80 ||
        value.trim().isEmpty ||
        !operatorsFor(field).contains(operator)) {
      return false;
    }
    return field == ImportRuleField.amount
        ? _amountMinor != null
        : currency == null;
  }

  int? get _amountMinor {
    final code = currency;
    if (!currencyMinorDigits.containsKey(code)) return null;
    try {
      return parseMoney(value, code!, allowZero: true);
    } on MoneyInputException {
      return null;
    }
  }

  bool matches(ImportRuleInput input) {
    if (field == ImportRuleField.amount) {
      if (input.currency != currency) return false;
      final threshold = _amountMinor;
      if (threshold == null) return false;
      return switch (operator) {
        ImportRuleOperator.equals => input.amountMinor == threshold,
        ImportRuleOperator.atLeast => input.amountMinor >= threshold,
        ImportRuleOperator.atMost => input.amountMinor <= threshold,
        _ => false,
      };
    }
    final values = input.fields[field] ?? const [];
    final expected = value.trim().toLowerCase();
    if (expected.isEmpty) return false;
    return switch (operator) {
      // Join description and note as in the original keyword rules.
      ImportRuleOperator.contains =>
        values.join('\n').toLowerCase().contains(expected),
      ImportRuleOperator.equals => values.any(
        (text) => text.trim().toLowerCase() == expected,
      ),
      ImportRuleOperator.startsWith => values.any(
        (text) => text.trimLeft().toLowerCase().startsWith(expected),
      ),
      _ => false,
    };
  }

  Map<String, Object> toJson() => {
    'field': field.name,
    'operator': operator.name,
    'value': value,
    'currency': ?currency,
  };

  static ImportRuleCondition? fromJson(Object? source) {
    if (source case {
      'field': String fieldName,
      'operator': String operatorName,
      'value': String value,
    }) {
      final field = ImportRuleField.values.asNameMap()[fieldName];
      final operator = ImportRuleOperator.values.asNameMap()[operatorName];
      final currency = (source as Map)['currency'];
      if (field != null &&
          operator != null &&
          (currency == null || currency is String)) {
        final condition = ImportRuleCondition(
          field: field,
          operator: operator,
          value: value,
          currency: currency as String?,
        );
        if (condition.isValid) return condition;
      }
    }
    return null;
  }
}

typedef ImportRuleInput = ({
  Map<ImportRuleField, List<String>> fields,
  int amountMinor,
  String currency,
});

class ImportCategoryRule {
  const ImportCategoryRule({
    required this.id,
    required this.conditions,
    required this.categoryId,
    this.mode = ImportRuleMode.all,
    this.priority = 100,
    this.enabled = true,
  });

  final String id;
  final List<ImportRuleCondition> conditions;
  final String categoryId;
  final ImportRuleMode mode;
  final int priority;
  final bool enabled;

  bool get isValid =>
      categoryId.isNotEmpty &&
      priority >= 0 &&
      priority <= 9999 &&
      conditions.isNotEmpty &&
      conditions.every((condition) => condition.isValid);

  bool matches(ImportRuleInput input) =>
      conditions.isNotEmpty &&
      switch (mode) {
        ImportRuleMode.all => conditions.every(
          (condition) => condition.matches(input),
        ),
        ImportRuleMode.any => conditions.any(
          (condition) => condition.matches(input),
        ),
      };
}

class ImportCategorySuggestion {
  ImportCategorySuggestion._(List<ImportCategoryRule> sorted)
    : matchedRules = List.unmodifiable(sorted);

  final List<ImportCategoryRule> matchedRules;

  int get priority => matchedRules.first.priority;

  String? get categoryId {
    final first = matchedRules.first.categoryId;
    return matchedRules
            .takeWhile((rule) => rule.priority == priority)
            .every((rule) => rule.categoryId == first)
        ? first
        : null;
  }
}

ImportCategorySuggestion? suggestImportCategory({
  required Iterable<ImportCategoryRule> rules,
  required ImportRuleInput input,
  required Set<String> eligibleCategories,
}) {
  final matching =
      rules
          .where(
            (rule) =>
                rule.enabled &&
                eligibleCategories.contains(rule.categoryId) &&
                rule.matches(input),
          )
          .toList()
        ..sort((left, right) {
          final priority = left.priority.compareTo(right.priority);
          return priority == 0 ? left.id.compareTo(right.id) : priority;
        });
  return matching.isEmpty ? null : ImportCategorySuggestion._(matching);
}
