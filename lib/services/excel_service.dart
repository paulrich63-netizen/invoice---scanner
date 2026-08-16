import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/invoice_entry.dart';

class ExcelService {
  Future<File> exportToExcel(List<InvoiceEntry> entries) async {
    final excel = Excel.createExcel();
    // Rename the default sheet
    excel.rename('Sheet1', 'Invoices');
    final sheet = excel['Invoices'];

    // Header row
    final headers = [
      'Date',
      'Due Date',
      'Invoice Number',
      'Supplier',
      'Total',
      'Tax / VAT',
      'Currency',
      'Description',
      'Created At',
      'Has Image',
    ];

    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Data rows
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final row = i + 1;
      final values = [
        e.date,
        e.dueDate,
        e.invoiceNumber,
        e.supplier,
        e.total,
        e.tax,
        e.currency,
        e.description,
        e.createdAt,
        e.hasImage ? 'Yes' : 'No',
      ];
      for (var col = 0; col < values.length; col++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
            .value = TextCellValue(values[col]);
      }
    }

    // Auto-size-ish column widths (approximate)
    sheet.setColumnWidth(0, 14);
    sheet.setColumnWidth(1, 14);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 28);
    sheet.setColumnWidth(4, 12);
    sheet.setColumnWidth(5, 12);
    sheet.setColumnWidth(6, 10);
    sheet.setColumnWidth(7, 40);
    sheet.setColumnWidth(8, 22);
    sheet.setColumnWidth(9, 12);

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
