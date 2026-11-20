import 'package:drift/drift.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/domain/accounts/ledger_account.dart';
import 'package:summa/domain/import_export/ledger_backup.dart';
import 'package:summa/domain/planning/debt_contract.dart';
import 'package:summa/domain/planning/planning_date.dart';

class DriftDebtContractStore {
  DriftDebtContractStore(this._db);

  final AppDatabase _db;

  Future<List<DebtContractRow>> _contracts() =>
      (_db.select(_db.debtContracts)..orderBy([
            (row) => OrderingTerm.asc(row.name),
            (row) => OrderingTerm.asc(row.accountId),
          ]))
          .get();

  Future<DebtContractRow?> byAccount(String accountId) => (_db.select(
    _db.debtContracts,
  )..where((row) => row.accountId.equals(accountId))).getSingleOrNull();

  Future<List<DebtInstallmentRow>> _installments() => (_db.select(
    _db.debtInstallments,
  )..orderBy([(row) => OrderingTerm.asc(row.dueOn)])).get();

  Stream<List<DebtContract>> watch(Selectable<QueryRow> balances) => _db
      .customSelect(
        'SELECT account_id FROM debt_contracts',
        readsFrom: {
          _db.debtContracts,
          _db.debtInstallments,
          _db.debtSettlements,
          _db.ledgerAccounts,
          _db.ledgerEntries,
          _db.ledgerPostings,
        },
      )
      .watch()
      .asyncMap(
        (_) => _db.transaction(() async {
          final contracts = await _contracts();
          if (contracts.isEmpty) return <DebtContract>[];
          final installments = _group(
            await _installments(),
            (row) => row.accountId,
          );
          final links = _group(
            await _db.select(_db.debtSettlements).get(),
            (row) => row.accountId,
          );
          final accounts = {
            for (final row in await balances.get()) row.read<String>('id'): row,
          };
          return [
            for (final contract in contracts)
              DebtContract(
                draft: _draft(
                  contract,
                  installments[contract.accountId] ?? const [],
                ),
                accountName: accounts[contract.accountId]!.read<String>('name'),
                balanceMinor: accounts[contract.accountId]!.read<int>(
                  'current_balance',
                ),
                links: [
                  for (final row
                      in links[contract.accountId] ??
                          const <DebtSettlementRow>[])
                    (
                      id: row.id,
                      entryId: row.entryId,
                      kind: DebtLinkKind.values.byName(row.kind),
                      voided: row.voided,
                    ),
                ],
              ),
          ];
        }),
      );

  Future<void> add(DebtContractDraft draft) async {
    if (!draft.isValid || !await _validAccount(draft, activeOnly: true)) {
      throw const DebtContractException(DebtContractError.invalid);
    }
    if (await byAccount(draft.accountId) != null) {
      throw const DebtContractException(DebtContractError.accountInUse);
    }
    await _insert(
      DebtContractRow(
        accountId: draft.accountId,
        name: draft.name.trim(),
        counterparty: draft.counterparty.trim(),
        direction: draft.direction.name,
        currency: draft.currency,
        originalPrincipalMinor: draft.originalPrincipalMinor,
        expectedInterestMinor: draft.expectedInterestMinor,
        dueOn: encodePlanningDay(draft.dueOn),
      ),
      [
        for (final row in draft.installments)
          DebtInstallmentRow(
            accountId: draft.accountId,
            dueOn: encodePlanningDay(row.dueOn),
            principalMinor: row.principalMinor,
            interestMinor: row.interestMinor,
          ),
      ],
    );
  }

  Future<bool> _validAccount(
    DebtContractDraft draft, {
    required bool activeOnly,
  }) async {
    final account = await (_db.select(
      _db.ledgerAccounts,
    )..where((row) => row.id.equals(draft.accountId))).getSingleOrNull();
    return account != null &&
        (!activeOnly || !account.isArchived) &&
        account.currencyCode == draft.currency &&
        DebtDirection.forAccount(AccountKind.values.byName(account.kind)) ==
            draft.direction;
  }

  Future<void> _insert(
    DebtContractRow row,
    List<DebtInstallmentRow> installments,
  ) => _db.batch((batch) {
    batch.insert(_db.debtContracts, row);
    batch.insertAll(_db.debtInstallments, installments);
  });

  Future<DebtSettlementRow?> _activeLink(String entryId) =>
      (_db.select(_db.debtSettlements)..where(
            (row) => row.entryId.equals(entryId) & row.voided.equals(false),
          ))
          .getSingleOrNull();

  Future<void> link(
    String id,
    String accountId,
    String entryId,
    DebtLinkKind kind,
  ) async {
    if (await _activeLink(entryId) != null) {
      throw const DebtContractException(DebtContractError.conflict);
    }
    await _db
        .into(_db.debtSettlements)
        .insert(
          DebtSettlementRow(
            id: id,
            accountId: accountId,
            entryId: entryId,
            kind: kind.name,
            voided: false,
          ),
        );
  }

  Future<void> unlink(String id) async {
    final updated =
        await (_db.update(_db.debtSettlements)
              ..where((row) => row.id.equals(id)))
            .write(const DebtSettlementsCompanion(voided: Value(true)));
    if (updated == 0) {
      throw const DebtContractException(DebtContractError.unavailable);
    }
  }

  Future<List<Map<String, Object>>> backup() async {
    final installments = _group(await _installments(), (row) => row.accountId);
    final links = _group(
      await (_db.select(
        _db.debtSettlements,
      )..orderBy([(row) => OrderingTerm.asc(row.id)])).get(),
      (row) => row.accountId,
    );
    return [
      for (final row in await _contracts())
        {
          'account_id': row.accountId,
          'name': row.name,
          'counterparty': row.counterparty,
          'direction': row.direction,
          'currency_code': row.currency,
          'original_principal_minor': row.originalPrincipalMinor,
          'expected_interest_minor': row.expectedInterestMinor,
          'due_on': row.dueOn,
          'installments': [
            for (final item
                in installments[row.accountId] ?? const <DebtInstallmentRow>[])
              {
                'due_on': item.dueOn,
                'principal_minor': item.principalMinor,
                'interest_minor': item.interestMinor,
              },
          ],
          'links': [
            for (final link
                in links[row.accountId] ?? const <DebtSettlementRow>[])
              {
                'id': link.id,
                'entry_id': link.entryId,
                'kind': link.kind,
                'voided': link.voided,
              },
          ],
        },
    ];
  }

  Future<void> restore(List<Map<String, dynamic>> source) async {
    final accountIds = <String>{};
    final linkIds = <String>{};
    final activeEntries = <String>{};
    final pendingLinks = <DebtSettlementRow>[];
    final existingInstallments = _group(
      await _installments(),
      (row) => row.accountId,
    );
    for (final raw in source) {
      final row = _contractFromBackup(raw);
      final installments = <DebtInstallmentRow>[
        for (final item in raw['installments'] as List<dynamic>)
          _installmentFromBackup(row.accountId, item),
      ];
      final draft = _draft(row, installments);
      if (!accountIds.add(row.accountId) ||
          !draft.isValid ||
          !await _validAccount(draft, activeOnly: false)) {
        throw debtBackupConflict;
      }
      final old = await byAccount(row.accountId);
      if (old == null) {
        await _insert(row, installments);
      } else {
        final previous =
            existingInstallments[row.accountId] ?? const <DebtInstallmentRow>[];
        if (old != row ||
            previous.length != installments.length ||
            installments.indexed.any(
              (entry) => previous[entry.$1] != entry.$2,
            )) {
          throw debtBackupConflict;
        }
      }
      for (final item in raw['links'] as List<dynamic>) {
        final link = _linkFromBackup(row, item);
        if (!linkIds.add(link.id) ||
            (!link.voided && !activeEntries.add(link.entryId))) {
          throw debtBackupConflict;
        }
        pendingLinks.add(link);
      }
    }
    // Apply removals first so a later replacement link can take the same entry.
    for (final link in pendingLinks.where((row) => row.voided)) {
      await _restoreLink(link);
    }
    for (final link in pendingLinks.where((row) => !row.voided)) {
      await _restoreLink(link);
    }

    final installments = _group(await _installments(), (row) => row.accountId);
    for (final row in await _contracts()) {
      if (!await _validAccount(
        _draft(row, installments[row.accountId] ?? const []),
        activeOnly: false,
      )) {
        throw debtBackupConflict;
      }
    }
  }

  Future<void> _restoreLink(DebtSettlementRow item) async {
    final links = _db.debtSettlements;
    final current = await (_db.select(
      links,
    )..where((row) => row.id.equals(item.id))).getSingleOrNull();
    if (current != null) {
      if (current.copyWith(voided: item.voided) != item) {
        throw debtBackupConflict;
      }
      if (item.voided && !current.voided) await unlink(item.id);
      return;
    }
    if (!item.voided && await _activeLink(item.entryId) != null) {
      throw debtBackupConflict;
    }
    final entries = _db.ledgerEntries;
    final entry =
        await (_db.selectOnly(entries)
              ..addColumns([entries.id])
              ..where(entries.id.equals(item.entryId)))
            .getSingleOrNull();
    if (entry == null) throw debtBackupConflict;
    await _db.into(links).insert(item);
  }
}

Map<String, List<T>> _group<T>(List<T> rows, String Function(T) keyOf) {
  final result = <String, List<T>>{};
  for (final row in rows) {
    (result[keyOf(row)] ??= []).add(row);
  }
  return result;
}

DebtContractDraft _draft(
  DebtContractRow row,
  List<DebtInstallmentRow> installments,
) => DebtContractDraft(
  accountId: row.accountId,
  name: row.name,
  counterparty: row.counterparty,
  direction: DebtDirection.values.byName(row.direction),
  currency: row.currency,
  originalPrincipalMinor: row.originalPrincipalMinor,
  expectedInterestMinor: row.expectedInterestMinor,
  dueOn: decodePlanningDay(row.dueOn)!,
  installments: [
    for (final entry in installments)
      (
        dueOn: decodePlanningDay(entry.dueOn)!,
        principalMinor: entry.principalMinor,
        interestMinor: entry.interestMinor,
      ),
  ],
);

DebtContractRow _contractFromBackup(Map<String, dynamic> raw) {
  if (raw
      case {
        'account_id': String account,
        'name': String name,
        'counterparty': String counterparty,
        'direction': String direction,
        'currency_code': String currency,
        'original_principal_minor': int principal,
        'expected_interest_minor': int interest,
        'due_on': String due,
        'installments': List<dynamic> _,
        'links': List<dynamic> _,
      }
      when DebtDirection.values.any((value) => value.name == direction) &&
          decodePlanningDay(due) != null) {
    return DebtContractRow(
      accountId: account,
      name: name,
      counterparty: counterparty,
      direction: direction,
      currency: currency,
      originalPrincipalMinor: principal,
      expectedInterestMinor: interest,
      dueOn: due,
    );
  }
  throw debtBackupConflict;
}

DebtInstallmentRow _installmentFromBackup(String account, Object? raw) {
  if (raw
      case {
        'due_on': String due,
        'principal_minor': int principal,
        'interest_minor': int interest,
      }
      when decodePlanningDay(due) != null) {
    return DebtInstallmentRow(
      accountId: account,
      dueOn: due,
      principalMinor: principal,
      interestMinor: interest,
    );
  }
  throw debtBackupConflict;
}

DebtSettlementRow _linkFromBackup(DebtContractRow contract, Object? raw) {
  if (raw
      case {
        'id': String id,
        'entry_id': String entry,
        'kind': String kind,
        'voided': bool voided,
      }
      when id.isNotEmpty &&
          entry.isNotEmpty &&
          (kind == DebtLinkKind.principal.name ||
              kind == DebtLinkKind.interest.name &&
                  contract.direction == DebtDirection.receivable.name)) {
    return DebtSettlementRow(
      id: id,
      accountId: contract.accountId,
      entryId: entry,
      kind: kind,
      voided: voided,
    );
  }
  throw debtBackupConflict;
}

const debtBackupConflict = LedgerBackupException('备份中的债务合同或核销关联无效或存在冲突');
