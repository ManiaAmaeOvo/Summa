class LedgerCategory {
  const LedgerCategory({required this.id, required this.name, this.parentId});

  final String id;
  final String name;
  final String? parentId;

  bool get isParent => parentId == null;
}
