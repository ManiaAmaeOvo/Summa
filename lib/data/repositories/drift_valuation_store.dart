import 'package:drift/drift.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/data/database/app_database.dart';
import 'package:summa/domain/valuation/net_worth_valuation.dart';

class DriftValuationStore {
  DriftValuationStore(this._database);

  final AppDatabase _database;

  Stream<ValuationSettings> watchSettings() =>
      _settingsQuery().watch().map(_settings);

  Future<ValuationSettings> readSettings() async =>
      _settings(await _settingsQuery().get());

  Selectable<QueryRow> _settingsQuery() => _database.customSelect(
    '''
    SELECT COALESCE((SELECT base_currency FROM valuation_preferences WHERE id = 1), ?) AS selected_base,
           rate.base_currency, rate.source_currency, rate.rate, rate.updated_at
    FROM (SELECT 1)
    LEFT JOIN valuation_rates AS rate ON true
    ORDER BY rate.base_currency, rate.source_currency
    ''',
    variables: [Variable.withString(defaultCurrency)],
    readsFrom: {_database.valuationPreferences, _database.valuationRates},
  );

  ValuationSettings _settings(List<QueryRow> rows) => ValuationSettings(
    baseCurrency: rows.first.read<String>('selected_base'),
    rates: List.unmodifiable([
      for (final row in rows)
        if (row.readNullable<String>('source_currency') case final code?)
          ValuationRate(
            sourceCurrency: code,
            baseCurrency: row.read<String>('base_currency'),
            rate: row.read<String>('rate'),
            updatedAt: row.read<DateTime>('updated_at'),
          ),
    ]),
  );

  Future<void> setBaseCurrency(String baseCurrency) async {
    if (!isValuationCurrency(baseCurrency)) {
      throw ArgumentError.value(
        baseCurrency,
        'baseCurrency',
        'unsupported currency',
      );
    }
    await _database
        .into(_database.valuationPreferences)
        .insertOnConflictUpdate(
          ValuationPreferencesCompanion.insert(
            id: const Value(1),
            baseCurrency: baseCurrency,
          ),
        );
  }

  Future<void> saveRate({
    required String sourceCurrency,
    required String baseCurrency,
    required String rate,
  }) async {
    final value = rate.trim();
    if (!isValidValuationRate(
      sourceCurrency: sourceCurrency,
      baseCurrency: baseCurrency,
      rate: value,
    )) {
      throw ArgumentError(
        'A valuation rate needs two supported currencies and a positive decimal',
      );
    }
    await _database
        .into(_database.valuationRates)
        .insertOnConflictUpdate(
          _rateInsert(
            ValuationRate(
              sourceCurrency: sourceCurrency,
              baseCurrency: baseCurrency,
              rate: value,
              updatedAt: DateTime.now(),
            ),
          ),
        );
  }

  Future<void> removeRate({
    required String sourceCurrency,
    required String baseCurrency,
  }) async {
    await (_database.delete(_database.valuationRates)..where(
          (row) =>
              row.sourceCurrency.equals(sourceCurrency) &
              row.baseCurrency.equals(baseCurrency),
        ))
        .go();
  }

  // Called inside the full-backup restore transaction.
  Future<void> restore(
    ValuationSettings snapshot, {
    required bool replace,
  }) async {
    if (replace) {
      await _database.delete(_database.valuationRates).go();
      await setBaseCurrency(snapshot.baseCurrency);
    }
    final existing = <(String, String), DateTime>{
      if (!replace)
        for (final row
            in await _database.select(_database.valuationRates).get())
          (row.baseCurrency, row.sourceCurrency): row.updatedAt,
    };
    final toSave = <ValuationRatesCompanion>[];
    for (final rate in snapshot.rates) {
      final last = existing[(rate.baseCurrency, rate.sourceCurrency)];
      if (last == null || rate.updatedAt.isAfter(last)) {
        toSave.add(_rateInsert(rate));
      }
    }
    await _database.batch(
      (batch) =>
          batch.insertAllOnConflictUpdate(_database.valuationRates, toSave),
    );
  }

  ValuationRatesCompanion _rateInsert(ValuationRate rate) =>
      ValuationRatesCompanion.insert(
        baseCurrency: rate.baseCurrency,
        sourceCurrency: rate.sourceCurrency,
        rate: rate.rate,
        updatedAt: rate.updatedAt,
      );
}
