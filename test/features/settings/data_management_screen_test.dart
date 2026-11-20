import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summa/app/providers.dart';
import 'package:summa/data/backup/local_backup_store.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/data/repositories/drift_expense_repository.dart';
import 'package:summa/domain/import_export/local_backup.dart';
import 'package:summa/features/settings/data_management_screen.dart';
import 'package:summa/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'saving and renaming a manual snapshot close the name dialog safely',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final store = _SnapshotStore();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseRepositoryProvider.overrideWithValue(
              _SnapshotRepository(db),
            ),
            localBackupStoreProvider.overrideWithValue(store),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: DataManagementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final start = find.text('Back up inside the app');
      await tester.scrollUntilVisible(
        start,
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(start);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Final acceptance');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(store.node?.name, 'Final acceptance');
      expect(tester.takeException(), isNull);

      final manual = find.widgetWithText(ListTile, 'Final acceptance');
      await tester.scrollUntilVisible(
        manual,
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.descendant(
          of: manual,
          matching: find.byWidgetPredicate(
            (widget) => widget is PopupMenuButton,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Phase 2 acceptance');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(store.node?.name, 'Phase 2 acceptance');
      expect(tester.takeException(), isNull);
    },
  );
}

class _SnapshotStore extends LocalBackupStore {
  LocalBackupNode? node;

  @override
  Future<String> get location async => '/test/backups';

  @override
  Future<List<LocalBackupNode>> listBackups() async => [?node];

  @override
  Future<LocalBackupNode> createManualBackup(
    String content, {
    String? name,
  }) async {
    return node = LocalBackupNode(
      path: '/test/backups/snapshot.json',
      kind: LocalBackupKind.manual,
      name: name!,
      createdAt: DateTime(2026, 11, 20),
      sizeBytes: content.length,
    );
  }

  @override
  Future<LocalBackupNode> renameBackup(
    LocalBackupNode existing,
    String name,
  ) async {
    return node = LocalBackupNode(
      path: existing.path,
      kind: existing.kind,
      name: name,
      createdAt: existing.createdAt,
      sizeBytes: existing.sizeBytes,
    );
  }
}

class _SnapshotRepository extends DriftExpenseRepository {
  _SnapshotRepository(super.database);

  @override
  Future<String> createFullBackup() async => '{}';
}
