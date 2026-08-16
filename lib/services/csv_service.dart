import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/invoice_entry.dart';

class CsvService {
  Future<File> exportToCsv(List<InvoiceEntry> entries) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File(p.join(dir.path, 'invoices_$timestamp.csv'));

    final buffer = StringBuffer();
    buffer.writeln(
        'Date,DueDate,InvoiceNumber,Supplier,Total,Tax,Currency,Description,CreatedAt,HasImage');

    for (final e in entries) {
      buffer.writeln(
        '"${_escape(e.date)}",'
        '"${_escape(e.dueDate)}",'
        '"${_escape(e.invoiceNumber)}",'
        '"${_escape(e.supplier)}",'
        '"${_escape(e.total)}",'
        '"${_escape(e.tax)}",'
        '"${_escape(e.currency)}",'
        '"${_escape(e.description)}",'
        '"${_escape(e.createdAt)}",'
        '"${e.hasImage ? 'Yes' : 'No'}"',
      );
    }

    await file.writeAsString(buffer.toString());
    return file;
  }

  String _escape(String value) => value.replaceAll('"', '""');
}
