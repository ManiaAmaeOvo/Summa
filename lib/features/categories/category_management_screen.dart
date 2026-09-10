import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger_pro/app/providers.dart';
import 'package:ledger_pro/domain/categories/ledger_category.dart';
import 'package:ledger_pro/domain/transactions/expense_record.dart';
import 'package:ledger_pro/l10n/default_ledger_labels.dart';
import 'package:ledger_pro/l10n/l10n.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.categoryManagement),
          bottom: TabBar(
            tabs: [
              Tab(text: context.l10n.expense),
              Tab(text: context.l10n.income),
            ],
          ),
          actions: [
            IconButton(
              tooltip: context.l10n.restoreDefaultCategories,
              icon: const Icon(Icons.restore),
              onPressed: () => _restoreDefaults(context, ref),
            ),
          ],
        ),
        body: const TabBarView(
          children: [
            _CategoryPane(type: LedgerTransactionType.expense),
            _CategoryPane(type: LedgerTransactionType.income),
          ],
        ),
      ),
    );
  }

  Future<void> _restoreDefaults(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.restoreDefaultCategoriesTitle),
        content: Text(context.l10n.restoreDefaultCategoriesDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.restore),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(expenseRepositoryProvider).restoreDefaultCategories();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.defaultCategoriesRestored)),
      );
    }
  }
}

class _CategoryPane extends ConsumerWidget {
  const _CategoryPane({required this.type});

  final LedgerTransactionType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(
      type == LedgerTransactionType.expense
          ? expenseCategoriesProvider
          : incomeCategoriesProvider,
    );
    return categories.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(context.l10n.categoryReadFailed)),
      data: (items) {
        final parents = items.where((item) => item.isParent).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Card.filled(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  context.l10n.categoryStructureHint,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final parent in parents)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ParentCategoryTile(
                  type: type,
                  parent: parent,
                  children: items
                      .where((item) => item.parentId == parent.id)
                      .toList(),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _showNameDialog(
                context,
                title: context.l10n.addPrimaryCategory,
                actionLabel: context.l10n.add,
                onSave: (name) => ref
                    .read(expenseRepositoryProvider)
                    .addCategory(type: type, name: name),
              ),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.addPrimaryCategory),
            ),
          ],
        );
      },
    );
  }
}

class _ParentCategoryTile extends ConsumerWidget {
  const _ParentCategoryTile({
    required this.type,
    required this.parent,
    required this.children,
  });

  final LedgerTransactionType type;
  final LedgerCategory parent;
  final List<LedgerCategory> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: true,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(DefaultLedgerLabels.category(context, parent)),
        subtitle: Text(context.l10n.secondaryCategoryCount(children.length)),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _parentAction(context, ref, action),
          itemBuilder: (_) => [
            PopupMenuItem(value: 'rename', child: Text(context.l10n.rename)),
            PopupMenuItem(value: 'up', child: Text(context.l10n.moveUp)),
            PopupMenuItem(value: 'down', child: Text(context.l10n.moveDown)),
            PopupMenuItem(
              value: 'archive',
              child: Text(context.l10n.archiveCategory),
            ),
          ],
        ),
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const Divider(height: 1, indent: 16),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 28, right: 8),
              leading: const Icon(Icons.subdirectory_arrow_right, size: 20),
              title: Text(
                DefaultLedgerLabels.category(context, children[index]),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (action) =>
                    _childAction(context, ref, children[index], action),
                itemBuilder: (_) => [
                  if (!DefaultLedgerLabels.isProtectedOther(children[index]))
                    PopupMenuItem(
                      value: 'rename',
                      child: Text(context.l10n.rename),
                    ),
                  PopupMenuItem(value: 'up', child: Text(context.l10n.moveUp)),
                  PopupMenuItem(
                    value: 'down',
                    child: Text(context.l10n.moveDown),
                  ),
                  if (!DefaultLedgerLabels.isProtectedOther(children[index]))
                    PopupMenuItem(
                      value: 'archive',
                      child: Text(context.l10n.archiveCategory),
                    ),
                ],
              ),
            ),
          ],
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(context.l10n.addSecondaryCategory),
            onTap: () => _showNameDialog(
              context,
              title: context.l10n.addToCategory(
                DefaultLedgerLabels.category(context, parent),
              ),
              actionLabel: context.l10n.add,
              onSave: (name) => ref
                  .read(expenseRepositoryProvider)
                  .addCategory(type: type, name: name, parentId: parent.id),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _parentAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    if (action == 'rename') {
      await _showNameDialog(
        context,
        title: context.l10n.renamePrimaryCategory,
        initialValue: DefaultLedgerLabels.category(context, parent),
        actionLabel: context.l10n.save,
        onSave: (name) => ref
            .read(expenseRepositoryProvider)
            .renameCategory(id: parent.id, name: name),
      );
    } else if (action == 'up' || action == 'down') {
      await ref
          .read(expenseRepositoryProvider)
          .moveCategory(parent.id, moveUp: action == 'up');
    } else if (action == 'archive') {
      await _confirmArchive(context, ref, parent, includesChildren: true);
    }
  }

  Future<void> _childAction(
    BuildContext context,
    WidgetRef ref,
    LedgerCategory child,
    String action,
  ) async {
    if (action == 'rename') {
      await _showNameDialog(
        context,
        title: context.l10n.renameSecondaryCategory,
        initialValue: DefaultLedgerLabels.category(context, child),
        actionLabel: context.l10n.save,
        onSave: (name) => ref
            .read(expenseRepositoryProvider)
            .renameCategory(id: child.id, name: name),
      );
    } else if (action == 'up' || action == 'down') {
      await ref
          .read(expenseRepositoryProvider)
          .moveCategory(child.id, moveUp: action == 'up');
    } else if (action == 'archive') {
      await _confirmArchive(context, ref, child);
    }
  }
}

Future<void> _confirmArchive(
  BuildContext context,
  WidgetRef ref,
  LedgerCategory category, {
  bool includesChildren = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        context.l10n.archiveCategoryTitle(
          DefaultLedgerLabels.category(context, category),
        ),
      ),
      content: Text(
        includesChildren
            ? context.l10n.archivePrimaryCategoryDescription
            : context.l10n.archiveSecondaryCategoryDescription,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.l10n.archive),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await ref.read(expenseRepositoryProvider).archiveCategory(category.id);
  }
}

Future<void> _showNameDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
  required String actionLabel,
  required Future<void> Function(String name) onSave,
}) async {
  final controller = TextEditingController(text: initialValue);
  String? error;
  var saving = false;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: InputDecoration(
            labelText: context.l10n.categoryName,
            errorText: error,
            helperText: context.l10n.categoryNameNoSlash,
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    setState(() {
                      saving = true;
                      error = null;
                    });
                    try {
                      await onSave(controller.text);
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    } catch (_) {
                      if (dialogContext.mounted) {
                        setState(() {
                          saving = false;
                          error = context.l10n.categoryNameInvalidOrDuplicate;
                        });
                      }
                    }
                  },
            child: Text(saving ? context.l10n.saving : actionLabel),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
}
