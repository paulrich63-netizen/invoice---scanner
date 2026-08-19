import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/invoice_entry.dart';

class ExcelService {
  Future<File> exportToExcel(List<InvoiceEntry> entries) async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Invoices');
    final sheet = excel['Invoices'];

    final headers = [
      'Date',
      'Supplier',
      'Net',
      'VAT 20%',
      'VAT 5%',
      'Zero Rated',
      'Total',
      'Currency',
      'Description',
    ];

    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center);
    }

    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final row = i + 1;
      final values = [
        e.date,
        e.supplier,
        e.net,
        e.vat20,
        e.vat5,
        e.zeroRated,
        e.total,
        e.currency,
        e.description,
      ];
      for (var col = 0; col < values.length; col++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
            .value = TextCellValue(values[col]);
      }
    }

    // Approximate column widths
    sheet.setColumnWidth(0, 12);
    sheet.setColumnWidth(1, 28);
    sheet.setColumnWidth(2, 12);
    sheet.setColumnWidth(3, 12);
    sheet.setColumnWidth(4, 12);
    sheet.setColumnWidth(5, 12);
    sheet.setColumnWidth(6, 12);
    sheet.setColumnWidth(7, 10);
    sheet.setColumnWidth(8, 40);

    final dir = await getApplicationDocumentsDirectory();
    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File(p.join(dir.path, 'invoices_$timestamp.xlsx'));

    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }
    return file;
  }
}
