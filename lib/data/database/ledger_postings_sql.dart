// Preserve account effects and unresolved semantics from the pre-posting ledger.
const insertLegacyPostings = '''
INSERT INTO ledger_postings (
  transaction_id, position, account_id, currency_code, debit_minor, role, needs_review
)
WITH transaction_accounts AS (
  SELECT
    e.id AS transaction_id,
    e.transaction_type,
    e.amount_minor,
    source.id AS source_id,
    source.currency_code AS source_currency,
    source.kind = 'creditLine' AS source_is_liability,
    target.id AS target_id,
    target.currency_code AS target_currency,
    target.kind = 'creditLine' AS target_is_liability,
    CASE
      WHEN e.amount_minor <= 0 OR e.currency_code <> source.currency_code
        THEN 1
      WHEN e.transaction_type IN ('expense', 'income')
        THEN e.target_account_id IS NOT NULL
          OR (e.transaction_type = 'income' AND source.kind = 'creditLine')
      WHEN e.transaction_type IN ('borrowing', 'repayment', 'transfer')
        THEN target.id IS NULL OR source.id = target.id
          OR e.currency_code <> target.currency_code
          OR (e.transaction_type = 'borrowing' AND
            (source.kind <> 'creditLine' OR
             target.kind IN ('creditLine', 'entrustedFunds')))
          OR (e.transaction_type = 'repayment' AND
            (source.kind = 'creditLine' OR target.kind <> 'creditLine'))
          OR (e.transaction_type = 'transfer' AND
            (source.kind = 'creditLine' OR target.kind = 'creditLine'))
      ELSE 1
    END AS needs_review
  FROM ledger_entries AS e
  JOIN ledger_accounts AS source ON source.id = e.account_id
  LEFT JOIN ledger_accounts AS target ON target.id = e.target_account_id
  WHERE e.status = 'posted' AND e.refund_of_id IS NULL
    AND NOT EXISTS (
      SELECT 1 FROM ledger_postings AS p WHERE p.transaction_id = e.id
    )
),
account_postings AS (
  SELECT
    transaction_id, transaction_type, source_id AS account_id,
    source_currency AS currency_code, needs_review, 0 AS leg_order,
    CASE transaction_type
      WHEN 'expense' THEN -amount_minor
      WHEN 'income' THEN amount_minor
      WHEN 'borrowing' THEN
        CASE WHEN source_is_liability THEN -amount_minor ELSE amount_minor END
      WHEN 'repayment' THEN
        CASE WHEN source_is_liability THEN amount_minor ELSE -amount_minor END
      WHEN 'transfer' THEN
        CASE WHEN source_is_liability THEN amount_minor ELSE -amount_minor END
      ELSE 0
    END AS debit_minor
  FROM transaction_accounts
  UNION ALL
  SELECT
    transaction_id, transaction_type, target_id, target_currency, needs_review, 1,
    CASE WHEN target_is_liability THEN -1 ELSE 1 END *
    CASE WHEN transaction_type = 'repayment' THEN -amount_minor
         ELSE amount_minor END
  FROM transaction_accounts
  WHERE transaction_type IN ('borrowing', 'repayment', 'transfer')
    AND target_id <> source_id
),
postings AS (
  SELECT transaction_id, account_id, currency_code, debit_minor,
         'account' AS role, needs_review, leg_order
  FROM account_postings
  UNION ALL
  SELECT transaction_id, NULL, currency_code, -SUM(debit_minor),
         CASE WHEN needs_review = 1 THEN 'unclassified'
              ELSE transaction_type END,
         needs_review, 2
  FROM account_postings
  WHERE needs_review = 1 OR transaction_type IN ('expense', 'income')
  GROUP BY transaction_id, currency_code, transaction_type, needs_review
  HAVING SUM(debit_minor) <> 0
)
SELECT transaction_id,
       ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY leg_order, currency_code) - 1,
       account_id, currency_code, debit_minor, role, needs_review
FROM postings
''';
