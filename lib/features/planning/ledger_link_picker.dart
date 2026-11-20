import 'package:flutter/material.dart';
import 'package:summa/core/money/money.dart';
import 'package:summa/domain/transactions/expense_record.dart';
import 'package:summa/l10n/default_ledger_labels.dart';
import 'package:summa/l10n/l10n.dart';

Future<String?> pickLedgerLink(
  BuildContext context, {
  required String title,
  required String emptyLabel,
  required List<LedgerRecord> candidates,
}) => showModalBottomSheet<String>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (_) =>
      _LinkSheet(candidates: candidates, title: title, emptyLabel: emptyLabel),
);

class _LinkSheet extends StatefulWidget {
  const _LinkSheet({
    required this.candidates,
    required this.title,
    required this.emptyLabel,
  });

  final String title;
  final String emptyLabel;

  final List<LedgerRecord> candidates;

  @override
  State<_LinkSheet> createState() => _LinkSheetState();
}

class _LinkSheetState extends State<_LinkSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final candidates = widget.candidates
        .where(
          (record) =>
              linkedTransactionTitle(
                context,
                record,
              ).toLowerCase().contains(_search) ||
              _displayDate(
                context,
                record.occurredAt,
              ).toLowerCase().contains(_search) ||
              formatMoney(
                record.amountMinor,
                record.currencyCode,
              ).toLowerCase().contains(_search),
        )
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        heightFactor: 0.8,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (widget.candidates.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: labels.recurringSearch,
                    ),
                    onChanged: (value) =>
                        setState(() => _search = value.trim().toLowerCase()),
                  ),
                ),
              if (candidates.isEmpty)
                Expanded(child: Center(child: Text(widget.emptyLabel)))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: candidates.length,
                    itemBuilder: (context, index) {
                      final record = candidates[index];
                      return ListTile(
                        title: Text(linkedTransactionTitle(context, record)),
                        subtitle: Text(
                          _displayDate(context, record.occurredAt),
                        ),
                        trailing: Text(
                          formatMoney(record.amountMinor, record.currencyCode),
                        ),
                        onTap: () => Navigator.pop(context, record.id),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String linkedTransactionTitle(BuildContext context, LedgerRecord record) {
  if (record.note.trim().isNotEmpty) return record.note;
  return switch (record.type) {
    LedgerTransactionType.repayment => context.l10n.repayment,
    LedgerTransactionType.collection => context.l10n.collection,
    LedgerTransactionType.reimbursement => context.l10n.reimbursement,
    _ => DefaultLedgerLabels.categoryName(
      Localizations.localeOf(context),
      record.categoryId,
      record.categoryName,
    ),
  };
}

String _displayDate(BuildContext context, DateTime value) =>
    MaterialLocalizations.of(context).formatShortDate(value);
