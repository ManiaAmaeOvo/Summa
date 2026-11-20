import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:summa/domain/analytics/financial_report.dart';
import 'package:summa/domain/import_export/financial_report_export.dart';
import 'package:summa/domain/planning/planning_date.dart';
import 'package:summa/l10n/l10n.dart';

class FinancialReportExportDialog extends StatefulWidget {
  const FinancialReportExportDialog({super.key, required this.report});

  final FinancialReport report;

  @override
  State<FinancialReportExportDialog> createState() =>
      _FinancialReportExportDialogState();
}

class _FinancialReportExportDialogState
    extends State<FinancialReportExportDialog> {
  var _format = FinancialReportFormat.json;
  var _includeTransactions = false;
  var _includeSensitive = false;
  var _saving = false;
  var _failed = false;

  @override
  Widget build(BuildContext context) {
    final labels = context.l10n;
    final local = MaterialLocalizations.of(context);
    final report = widget.report;
    final start = local.formatShortDate(report.range.start);
    final end = local.formatShortDate(
      report.range.endExclusive.subtract(const Duration(microseconds: 1)),
    );
    return AlertDialog(
      scrollable: true,
      title: Text(labels.exportFinancialReport),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('$start – $end · ${report.currency}'),
          Text(labels.ledgerFilterMatched(report.transactions.length)),
          const SizedBox(height: 12),
          DropdownButtonFormField<FinancialReportFormat>(
            initialValue: _format,
            isExpanded: true,
            decoration: InputDecoration(labelText: labels.fileFormat),
            items: [
              for (final format in FinancialReportFormat.values)
                DropdownMenuItem(
                  value: format,
                  child: Text(switch (format) {
                    FinancialReportFormat.json => 'JSON',
                    FinancialReportFormat.csv => 'CSV',
                    FinancialReportFormat.xlsx => 'XLSX',
                    FinancialReportFormat.markdown => 'Markdown',
                  }),
                ),
            ],
            onChanged: _saving
                ? null
                : (format) {
                    if (format != null) setState(() => _format = format);
                  },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(labels.reportIncludeTransactions),
            value: _includeTransactions,
            onChanged: _saving
                ? null
                : (value) {
                    setState(() => _includeTransactions = value);
                  },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(labels.reportIncludeSensitive),
            value: _includeSensitive,
            onChanged: _saving
                ? null
                : (value) {
                    setState(() => _includeSensitive = value);
                  },
          ),
          if (_failed)
            Text(
              labels.reportExportFailed,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(labels.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? labels.preparing : labels.export),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final labels = context.l10n;
    final report = widget.report;
    final format = _format;
    final options = FinancialReportExport(
      includeTransactions: _includeTransactions,
      includeSensitiveFields: _includeSensitive,
      languageCode: Localizations.localeOf(context).languageCode,
    );
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      final bytes = await compute(_encode, (
        report,
        format,
        options,
        DateTime.now(),
      ));
      if (!mounted) return;
      final saved = await FilePicker.saveFile(
        dialogTitle: labels.exportFinancialReport,
        fileName:
            'summa-report-${encodePlanningDay(report.range.start)}'
            '-${report.currency}.${format.extension}',
        mimeType: format.mimeType,
        bytes: bytes,
      );
      if (mounted && saved != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(labels.reportExportSaved)));
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

Uint8List _encode(
  (FinancialReport, FinancialReportFormat, FinancialReportExport, DateTime)
  input,
) => input.$3.encode(input.$1, input.$2, exportedAt: input.$4);
