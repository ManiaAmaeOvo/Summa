import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:summa/domain/import_export/csv_import.dart';
import 'package:summa/domain/import_export/statement_import.dart';
import 'package:summa/l10n/l10n.dart';

Future<CsvImportFile?> pickStatementFile() async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: ['csv', 'xlsx'],
  );
  if (file == null) return null;
  if (await file.length() > maxCsvImportBytes) {
    throw const CsvImportException(CsvIssue.tooLarge);
  }
  return parseStatementImport(file.name, await file.readAsBytes());
}

Future<CsvImportFile?> pasteStatement(BuildContext context) async {
  final name = context.l10n.csvPastedFile;
  final source = await showDialog<String>(
    context: context,
    builder: (_) => const _PasteCsvDialog(),
  );
  return source == null
      ? null
      : parseStatementImport(name, utf8.encode(source));
}

class _PasteCsvDialog extends StatefulWidget {
  const _PasteCsvDialog();

  @override
  State<_PasteCsvDialog> createState() => _PasteCsvDialogState();
}

class _PasteCsvDialogState extends State<_PasteCsvDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.csvPaste),
    content: SizedBox(
      width: 540,
      child: TextField(
        controller: _controller,
        maxLines: 8,
        keyboardType: TextInputType.multiline,
        decoration: const InputDecoration(
          hintText: 'type,amount,occurred_at,account',
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text),
        child: Text(context.l10n.parseAndPreview),
      ),
    ],
  );
}
