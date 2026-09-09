import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger_pro/app/providers.dart';
import 'package:ledger_pro/domain/categories/ledger_category.dart';
import 'package:ledger_pro/domain/transactions/expense_record.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('分类管理'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '支出'),
              Tab(text: '收入'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: '恢复默认分类',
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
        title: const Text('恢复默认分类？'),
        content: const Text('只会重新启用缺失的默认分类，不会删除或重置自定义分类。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('恢复'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(expenseRepositoryProvider).restoreDefaultCategories();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('默认分类已恢复，自定义分类未受影响')));
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
      error: (_, _) => const Center(child: Text('分类读取失败')),
      data: (items) {
        final parents = items.where((item) => item.isParent).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            Card.filled(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  '一级分类用于汇总，二级分类用于每笔账单。历史账单会保留已停用分类的名称。',
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
                title: '添加一级分类',
                actionLabel: '添加',
                onSave: (name) => ref
                    .read(expenseRepositoryProvider)
                    .addCategory(type: type, name: name),
              ),
              icon: const Icon(Icons.add),
              label: const Text('添加一级分类'),
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
        title: Text(parent.name),
        subtitle: Text('${children.length} 个二级分类'),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _parentAction(context, ref, action),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'rename', child: Text('重命名')),
            PopupMenuItem(value: 'up', child: Text('向上移动')),
            PopupMenuItem(value: 'down', child: Text('向下移动')),
            PopupMenuItem(value: 'archive', child: Text('停用分类')),
          ],
        ),
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) const Divider(height: 1, indent: 16),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 28, right: 8),
              leading: const Icon(Icons.subdirectory_arrow_right, size: 20),
              title: Text(children[index].name),
              trailing: PopupMenuButton<String>(
                onSelected: (action) =>
                    _childAction(context, ref, children[index], action),
                itemBuilder: (_) => [
                  if (children[index].name != '其他')
                    const PopupMenuItem(value: 'rename', child: Text('重命名')),
                  const PopupMenuItem(value: 'up', child: Text('向上移动')),
                  const PopupMenuItem(value: 'down', child: Text('向下移动')),
                  if (children[index].name != '其他')
                    const PopupMenuItem(value: 'archive', child: Text('停用分类')),
                ],
              ),
            ),
          ],
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('添加二级分类'),
            onTap: () => _showNameDialog(
              context,
              title: '添加到“${parent.name}”',
              actionLabel: '添加',
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
        title: '重命名一级分类',
        initialValue: parent.name,
        actionLabel: '保存',
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
        title: '重命名二级分类',
        initialValue: child.name,
        actionLabel: '保存',
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
      title: Text('停用“${category.name}”？'),
      content: Text(
        includesChildren
            ? '该一级分类及其二级分类将不再用于新账单，历史账单不受影响。'
            : '该分类将不再用于新账单，历史账单不受影响。',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('停用'),
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
            labelText: '分类名称',
            errorText: error,
            helperText: '名称不能包含 /',
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(dialogContext),
            child: const Text('取消'),
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
                          error = '名称无效或同级分类已存在';
                        });
                      }
                    }
                  },
            child: Text(saving ? '保存中…' : actionLabel),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
}
