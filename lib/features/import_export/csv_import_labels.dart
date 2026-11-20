import 'package:flutter/material.dart';
import 'package:summa/domain/import_export/csv_import.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/domain/transactions/expense_repository.dart';
import 'package:summa/l10n/l10n.dart';
import 'package:summa/l10n/transaction_rule_labels.dart';

String csvTypeLabel(BuildContext context, LedgerTransactionType type) =>
    switch (type) {
      LedgerTransactionType.expense => context.l10n.expense,
      LedgerTransactionType.income => context.l10n.income,
      LedgerTransactionType.transfer => context.l10n.transfer,
      LedgerTransactionType.borrowing => context.l10n.borrowing,
      LedgerTransactionType.repayment => context.l10n.repayment,
      _ => type.name,
    };

String csvStateLabel(BuildContext context, CsvReviewState state) =>
    switch (state) {
      CsvReviewState.ready => context.l10n.csvReady,
      CsvReviewState.unresolved => context.l10n.csvUnresolved,
      CsvReviewState.similar => context.l10n.csvSimilar,
      CsvReviewState.duplicate => context.l10n.csvDuplicate,
      CsvReviewState.conflict => context.l10n.csvSourceConflict,
      CsvReviewState.invalid => context.l10n.csvInvalid,
    };

String csvIssueLabel(BuildContext context, CsvIssue issue) => switch (issue) {
  CsvIssue.encoding => context.l10n.csvEncoding,
  CsvIssue.tooLarge => context.l10n.csvTooLarge,
  CsvIssue.empty => context.l10n.csvEmpty,
  CsvIssue.headers => context.l10n.csvHeaders,
  CsvIssue.syntax => context.l10n.csvSyntax,
  CsvIssue.columns => context.l10n.csvColumns,
  CsvIssue.type => context.l10n.csvTypeInvalid,
  CsvIssue.amount => context.l10n.csvAmountInvalid,
  CsvIssue.date => context.l10n.csvDateInvalid,
  CsvIssue.currency => context.l10n.csvCurrencyInvalid,
  CsvIssue.source => context.l10n.csvSourceRequired,
  CsvIssue.advanced => context.l10n.csvAdvanced,
};

String csvErrorText(BuildContext context, Object error) {
  final labels = context.l10n;
  final (message, line) = switch (error) {
    CsvImportException(:final issue, :final line) => (
      csvIssueLabel(context, issue),
      line,
    ),
    CsvBatchException(:final error, :final line) => (
      switch (error) {
        CsvBatchError.reviewChanged => labels.csvReviewChanged,
        CsvBatchError.modified => labels.csvUndoModified,
        CsvBatchError.linked => labels.csvUndoLinked,
        CsvBatchError.unavailable => labels.csvBatchUnavailable,
      },
      line,
    ),
    CsvPostingException(:final line, :final cause) => (
      cause is TransactionRuleException
          ? localizedTransactionRule(context, cause)
          : labels.invalidTransactionDetails,
      line,
    ),
    _ => (labels.csvOperationFailed, null),
  };
  return line == null ? message : '${labels.csvLine(line)} · $message';
}
