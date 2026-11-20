enum ImportRuleField { merchant, description, paymentChannel, source, account }

class ImportCategoryRule {
  const ImportCategoryRule({
    required this.id,
    required this.field,
    required this.keyword,
    required this.categoryId,
    this.priority = 100,
    this.enabled = true,
  });

  final String id;
  final ImportRuleField field;
  final String keyword;
  final String categoryId;
  final int priority;
  final bool enabled;
}

typedef ImportCategorySuggestion = ({String? categoryId, String keyword});

ImportCategorySuggestion? suggestImportCategory({
  required Iterable<ImportCategoryRule> rules,
  required Map<ImportRuleField, String> fields,
  required Set<String> eligibleCategories,
}) {
  final normalized = fields.map(
    (key, value) => MapEntry(key, value.toLowerCase()),
  );
  ImportCategoryRule? winner;
  var conflict = false;
  for (final rule in rules) {
    final keyword = rule.keyword.trim().toLowerCase();
    if (!rule.enabled ||
        keyword.isEmpty ||
        !eligibleCategories.contains(rule.categoryId) ||
        !(normalized[rule.field] ?? '').contains(keyword)) {
      continue;
    }
    if (winner == null || rule.priority < winner.priority) {
      winner = rule;
      conflict = false;
    } else if (rule.priority == winner.priority &&
        rule.categoryId != winner.categoryId) {
      conflict = true;
    }
  }
  return winner == null
      ? null
      : (
          categoryId: conflict ? null : winner.categoryId,
          keyword: winner.keyword,
        );
}
