import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String rawText;
  final String date;
  final String dueDate;
  final String invoiceNumber;
  final String supplier;
  final String total;
  final String tax;
  final String currency;
  final String description;

  OcrResult({
    required this.rawText,
    required this.date,
    this.dueDate = '',
    this.invoiceNumber = '',
    required this.supplier,
    required this.total,
    this.tax = '',
    this.currency = '',
    required this.description,
  });
}

class OcrService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<OcrResult> processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _recognizer.processImage(inputImage);
    return _parseInvoice(recognizedText.text);
  }

  OcrResult _parseInvoice(String text) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // ---- Invoice Number ----
    String invoiceNumber = '';
    final invPatterns = [
      RegExp(r'(?:invoice\s*(?:no|number|#|num)?[:\s]*)([A-Z0-9\-\/]+)',
          caseSensitive: false),
      RegExp(r'(?:inv[:\s#]*)([A-Z0-9\-\/]{4,})', caseSensitive: false),
      RegExp(r'#\s*([A-Z0-9\-\/]{4,})'),
    ];
    for (final p in invPatterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        invoiceNumber = m.group(1) ?? '';
        break;
      }
    }

    // ---- Date (invoice date) ----
    String date = '';
    final datePatterns = [
      RegExp(r'\b(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})\b'),
      RegExp(r'\b(\d{4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,2})\b'),
      RegExp(
          r'\b((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[\s\-]?\d{1,2},?\s?\d{2,4})\b',
          caseSensitive: false),
    ];
    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        date = match.group(1) ?? match.group(0) ?? '';
        break;
      }
    }

    // ---- Due Date ----
    String dueDate = '';
    final duePatterns = [
      RegExp(
          r'(?:due\s*(?:date)?|payment\s*due|pay\s*by)[^\d]{0,15}(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})',
          caseSensitive: false),
      RegExp(
          r'(?:due\s*(?:date)?|payment\s*due)[^\d]{0,15}(\d{4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,2})',
          caseSensitive: false),
    ];
    for (final p in duePatterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        dueDate = m.group(1) ?? '';
        break;
      }
    }

    // ---- Currency ----
    String currency = '';
    if (RegExp(r'€|EUR', caseSensitive: false).hasMatch(text)) {
      currency = 'EUR';
    } else if (RegExp(r'\$|USD', caseSensitive: false).hasMatch(text)) {
      currency = 'USD';
    } else if (RegExp(r'£|GBP', caseSensitive: false).hasMatch(text)) {
      currency = 'GBP';
    } else if (RegExp(r'CHF', caseSensitive: false).hasMatch(text)) {
      currency = 'CHF';
    }

    // ---- Total ----
    String total = '';
    final totalPatterns = [
      RegExp(
          r'(?:grand\s*total|amount\s*due|balance\s*due|total\s*due|total)[^\d]{0,25}([\d,]+\.?\d{0,2})',
          caseSensitive: false),
      RegExp(r'([\d,]+\.\d{2})\s*(?:EUR|USD|GBP|€|\$|£)?\s*$', multiLine: true),
      RegExp(r'(?:€|\$|£)\s*([\d,]+\.?\d{0,2})'),
    ];
    for (final pattern in totalPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        total = (match.group(1) ?? '').replaceAll(',', '');
        break;
      }
    }

    // ---- Tax / VAT ----
    String tax = '';
    final taxPatterns = [
      RegExp(
          r'(?:vat|tax|gst|mwst|tva)[^\d]{0,20}([\d,]+\.?\d{0,2})',
          caseSensitive: false),
      RegExp(r'([\d,]+\.?\d{0,2})\s*(?:vat|tax|gst)', caseSensitive: false),
    ];
    for (final p in taxPatterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        tax = (m.group(1) ?? '').replaceAll(',', '');
        break;
      }
    }

    // ---- Supplier (first meaningful line near the top) ----
    String supplier = '';
    for (var i = 0; i < lines.length && i < 12; i++) {
      final line = lines[i];
      if (line.length < 3) continue;
      if (RegExp(
              r'invoice|receipt|tax|date|total|amount|page|tel|phone|www\.|@|vat|gst|due|bill\s*to',
              caseSensitive: false)
          .hasMatch(line)) {
        continue;
      }
      if (RegExp(r'[A-Za-z]{3,}').hasMatch(line)) {
        supplier = line;
        break;
      }
    }

    // ---- Description ----
    String description = '';
    if (lines.length > 4) {
      description = lines
          .skip(2)
          .take(7)
          .join(' | ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (description.length > 280) {
        description = '${description.substring(0, 277)}...';
      }
    }

    return OcrResult(
      rawText: text,
      date: date,
      dueDate: dueDate,
      invoiceNumber: invoiceNumber,
      supplier: supplier,
      total: total,
      tax: tax,
      currency: currency,
      description: description,
    );
  }

  void dispose() {
    _recognizer.close();
  }
}
