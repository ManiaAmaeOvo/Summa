import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

typedef ReportWorkbookSheet = ({
  String name,
  List<String> columns,
  Iterable<Iterable<Object?>> rows,
});

const _sheetNamespace =
    'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
const _documentRels =
    'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
const _packageRels =
    'http://schemas.openxmlformats.org/package/2006/relationships';
const _contentTypes =
    'http://schemas.openxmlformats.org/package/2006/content-types';

Uint8List encodeReportWorkbook(List<ReportWorkbookSheet> sheets) {
  final archive = Archive();
  void add(String path, String xml) {
    archive.addFile(ArchiveFile.bytes(path, utf8.encode(xml)));
  }

  add('[Content_Types].xml', '''
<Types xmlns="$_contentTypes">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
  ${[for (var i = 1; i <= sheets.length; i++) '<Override PartName="/xl/worksheets/sheet$i.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'].join()}
</Types>''');
  add('_rels/.rels', '''
<Relationships xmlns="$_packageRels">
  <Relationship Id="rId1" Type="$_documentRels/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''');
  add('xl/_rels/workbook.xml.rels', '''
<Relationships xmlns="$_packageRels">
  <Relationship Id="styles" Type="$_documentRels/styles" Target="styles.xml"/>
  ${[for (var i = 1; i <= sheets.length; i++) '<Relationship Id="rId$i" Type="$_documentRels/worksheet" Target="worksheets/sheet$i.xml"/>'].join()}
</Relationships>''');
  final workbook = XmlBuilder();
  workbook.element(
    'workbook',
    attributes: {'xmlns': _sheetNamespace, 'xmlns:r': _documentRels},
    nest: () {
      workbook.element(
        'bookViews',
        nest: () => workbook.element('workbookView'),
      );
      workbook.element(
        'sheets',
        nest: () {
          for (final (index, sheet) in sheets.indexed) {
            workbook.element(
              'sheet',
              attributes: {
                'name': sheet.name,
                'sheetId': '${index + 1}',
                'r:id': 'rId${index + 1}',
              },
            );
          }
        },
      );
    },
  );
  add('xl/workbook.xml', workbook.buildDocument().toXmlString());
  add('xl/styles.xml', _styles);
  for (final (index, sheet) in sheets.indexed) {
    add('xl/worksheets/sheet${index + 1}.xml', _worksheet(sheet));
  }
  return ZipEncoder().encodeBytes(archive);
}

String _worksheet(ReportWorkbookSheet sheet) {
  final builder = XmlBuilder();
  var lines = 0;
  void row(Iterable<Object?> values) {
    lines += 1;
    if (lines > 1048576) throw StateError('XLSX worksheet row limit');
    builder.element(
      'row',
      attributes: {'r': '$lines'},
      nest: () {
        for (final (column, value) in values.indexed) {
          if (value == null) continue;
          final address = '${_columnName(column)}$lines';
          final numeric =
              value is int || (value is BigInt && value.abs() <= _maxNumeric);
          final text = _excelText(value.toString());
          builder.element(
            'c',
            attributes: {
              'r': address,
              't': numeric ? 'n' : 'inlineStr',
              if (lines == 1) 's': '1',
            },
            nest: () {
              if (numeric) {
                builder.element('v', nest: text);
              } else {
                builder.element(
                  'is',
                  nest: () {
                    builder.element(
                      't',
                      attributes: {'xml:space': 'preserve'},
                      nest: text,
                    );
                  },
                );
              }
            },
          );
        }
      },
    );
  }

  builder.element(
    'worksheet',
    attributes: {'xmlns': _sheetNamespace},
    nest: () {
      builder.element(
        'sheetViews',
        nest: () {
          builder.element(
            'sheetView',
            attributes: {'workbookViewId': '0'},
            nest: () {
              builder.element(
                'pane',
                attributes: {
                  'ySplit': '1',
                  'topLeftCell': 'A2',
                  'activePane': 'bottomLeft',
                  'state': 'frozen',
                },
              );
            },
          );
        },
      );
      final widths = [for (final column in sheet.columns) column.length + 4];
      for (final sample in sheet.rows.take(60)) {
        for (final (index, value) in sample.indexed) {
          final length = (value?.toString().length ?? 0) + 3;
          if (length > widths[index]) widths[index] = length;
        }
      }
      builder.element(
        'cols',
        nest: () {
          for (final (index, width) in widths.indexed) {
            builder.element(
              'col',
              attributes: {
                'min': '${index + 1}',
                'max': '${index + 1}',
                'width': '${width.clamp(14, 52)}',
                'customWidth': '1',
              },
            );
          }
        },
      );
      builder.element(
        'sheetData',
        nest: () {
          row(sheet.columns);
          for (final values in sheet.rows) {
            row(values);
          }
        },
      );
      if (lines > 1) {
        builder.element(
          'autoFilter',
          attributes: {
            'ref': 'A1:${_columnName(sheet.columns.length - 1)}$lines',
          },
        );
      }
    },
  );
  return builder.buildDocument().toXmlString();
}

final _maxNumeric = BigInt.parse('999999999999999');
final _excelEscape = RegExp(r'_x[0-9a-fA-F]{4}_');

String _excelText(String value) {
  // Excel interprets these sequences even in inline strings.
  final text = value.replaceAllMapped(
    _excelEscape,
    (match) => '_x005F_${match[0]!.substring(1)}',
  );
  final xml = String.fromCharCodes(
    text.runes.map(
      (code) =>
          code < 0x20 && code != 9 && code != 10 && code != 13 ||
              (code >= 0xd800 && code <= 0xdfff) ||
              code == 0xfffe ||
              code == 0xffff
          ? 0xfffd
          : code,
    ),
  );
  if (xml.length <= 32767) return xml;
  final last = xml.codeUnitAt(32765);
  final splitSurrogate = last >= 0xd800 && last <= 0xdbff;
  return '${xml.substring(0, splitSurrogate ? 32765 : 32766)}…';
}

String _columnName(int index) {
  var result = '';
  for (var number = index + 1; number > 0; number = (number - 1) ~/ 26) {
    result = String.fromCharCode(65 + (number - 1) % 26) + result;
  }
  return result;
}

const _styles =
    '''
<styleSheet xmlns="$_sheetNamespace">
  <fonts count="2">
    <font><sz val="11"/><name val="Calibri"/></font>
    <font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font>
  </fonts>
  <fills count="3">
    <fill><patternFill patternType="none"/></fill>
    <fill><patternFill patternType="gray125"/></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FF14594F"/><bgColor indexed="64"/></patternFill></fill>
  </fills>
  <borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
  <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
  <cellXfs count="2">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
    <xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/>
  </cellXfs>
  <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>''';
