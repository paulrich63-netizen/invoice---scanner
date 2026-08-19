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
    // Clean columns as requested
    buffer.writeln(
        'Date,Supplier,Net,VAT20,VAT5,ZeroRated,Total,Currency,Description');

    for (final e in entries) {
      buffer.writeln(
        '"${_escape(e.date)}",'
        '"${_escape(e.supplier)}",'
        '"${_escape(e.net)}",'
        '"${_escape(e.vat20)}",'
        '"${_escape(e.vat5)}",'
        '"${_escape(e.zeroRated)}",'
        '"${_escape(e.total)}",'
        '"${_escape(e.currency)}",'
        '"${_escape(e.description)}"',
      );
    }

    await file.writeAsString(buffer.toString());
    return file;
  }

  String _escape(String value) => value.replaceAll('"', '""');
}
