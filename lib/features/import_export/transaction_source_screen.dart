import 'package:flutter/material.dart';
import 'package:summa/domain/transactions/transaction_source.dart';
import 'package:summa/features/import_export/csv_import_history_screen.dart';
import 'package:summa/l10n/l10n.dart';

class TransactionSourceScreen extends StatelessWidget {
  const TransactionSourceScreen({super.key, required this.sources});

  final List<TransactionSource> sources;

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(labels.transactionSources)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final source in sources)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.batchName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(labels.csvLine(source.line)),
                    if (source.provider case final provider?) Text(provider),
                    if (source.channel case final channel?)
                      Text('${labels.paymentChannel} · $channel'),
                    if (source.counterparty case final party?)
                      Text('${labels.transactionCounterparty} · $party'),
                    const SizedBox(height: 8),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      title: Text(labels.importedRowFields),
                      children: [
                        for (final field in source.cells.entries)
                          if (field.value.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: SelectableText(
                                '${field.key} · ${field.value}',
                              ),
                            ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CsvBatchDetailsScreen(id: source.batchId),
                        ),
                      ),
                      icon: const Icon(Icons.description_outlined),
                      label: Text(labels.csvBatchDetails),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
