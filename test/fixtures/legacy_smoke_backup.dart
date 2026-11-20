const legacySmokeBackup = '''
{
  "format": "ledgerpro_full_backup",
  "backup_version": 1,
  "created_at": "2026-11-18T12:00:00.000",
  "accounts": [
    {
      "created_at": "2026-11-18T12:00:00.000",
      "updated_at": "2026-11-18T12:00:00.000",
      "id": "migration-smoke-cash",
      "name": "Migration test cash",
      "kind": "cash",
      "currency_code": "CNY",
      "opening_balance_minor": 10000,
      "sort_order": 0,
      "is_archived": false
    }
  ],
  "categories": [
    {
      "created_at": "2026-11-18T12:00:00.000",
      "updated_at": "2026-11-18T12:00:00.000",
      "sort_order": 0,
      "is_archived": false,
      "transaction_type": "expense",
      "id": "migration-smoke-parent",
      "name": "Migration test",
      "parent_id": null
    },
    {
      "created_at": "2026-11-18T12:00:00.000",
      "updated_at": "2026-11-18T12:00:00.000",
      "sort_order": 0,
      "is_archived": false,
      "transaction_type": "expense",
      "id": "migration-smoke-child",
      "name": "Migration test expense",
      "parent_id": "migration-smoke-parent"
    }
  ],
  "entries": [
    {
      "created_at": "2026-11-18T12:00:00.000",
      "updated_at": "2026-11-18T12:00:00.000",
      "id": "migration-smoke-record",
      "transaction_type": "expense",
      "amount_minor": 2345,
      "currency_code": "CNY",
      "occurred_at": "2026-11-18T12:00:00.000",
      "timezone_offset_minutes": 0,
      "category_id": "migration-smoke-child",
      "account_id": "migration-smoke-cash",
      "target_account_id": null,
      "note": "Migration smoke test",
      "is_deleted": false
    }
  ]
}
''';
