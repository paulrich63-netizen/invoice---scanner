import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String rawText;
  final String date;
  final String supplier;
  final String net;
  final String vat20;
  final String vat5;
  final String zeroRated;
  final String total;
  final String currency;
  final String description;

  OcrResult({
    required this.rawText,
    required this.date,
    required this.supplier,
    this.net = '',
    this.vat20 = '',
    this.vat5 = '',
    this.zeroRated = '',
    required this.total,
    this.currency = 'GBP',
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

    // ---- Currency ----
    String currency = 'GBP';
    if (RegExp(r'€|EUR', caseSensitive: false).hasMatch(text)) {
      currency = 'EUR';
    } else if (RegExp(r'\$|USD', caseSensitive: false).hasMatch(text)) {
      currency = 'USD';
    } else if (RegExp(r'£|GBP', caseSensitive: false).hasMatch(text)) {
      currency = 'GBP';
    }

    // ---- Invoice Date ----
    String date = '';
    final datePatterns = [
      RegExp(r'(?:invoice\s*date|date)[:\s]*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})', caseSensitive: false),
      RegExp(r'\b(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})\b'),
      RegExp(r'\b(\d{4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,2})\b'),
    ];
    for (final p in datePatterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        date = m.group(1) ?? m.group(0) ?? '';
        break;
      }
    }

    // ---- Supplier (first strong company-like line) ----
    String supplier = '';
    for (var i = 0; i < lines.length && i < 12; i++) {
      final line = lines[i];
      if (line.length < 4) continue;
      if (RegExp(r'invoice|receipt|tax|date|total|amount|page|tel|phone|www\.|@|vat|customer|order|labour|parts|quantity|rate|net',
              caseSensitive: false)
          .hasMatch(line)) continue;
      if (RegExp(r'[A-Za-z]{4,}').hasMatch(line) && !RegExp(r'^\d').hasMatch(line)) {
        supplier = line;
        // Prefer lines containing Ltd, Limited, PLC, etc.
        if (RegExp(r'\b(Ltd|Limited|PLC|LLP|Inc|LLC)\b', caseSensitive: false).hasMatch(line)) {
          break;
        }
      }
    }

    // ---- Net / Vatable Items ----
    String net = '';
    final netPatterns = [
      RegExp(r'(?:vatable\s*items|net\s*(?:amount|total)?|subtotal|goods)[^\d]{0,20}([\d,]+\.?\d{0,2})', caseSensitive: false),
      RegExp(r'([\d,]+\.\d{2})\s*(?:net|vatable)', caseSensitive: false),
    ];
    for (final p in netPatterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        net = (m.group(1) ?? '').replaceAll(',', '');
        break;
      }
    }

    // ---- VAT @ 20% ----
    String vat20 = '';
    final vat20Patterns = [
      RegExp(r'(?:vat\s*@?\s*20\.?0?0?%|20\.?0?0?%\s*vat)[^\d]{0,15}([\d,]+\.?\d{0,2})', caseSensitive: false),
      RegExp(r'([\d,]+\.\d{2})\s*(?:vat\s*@?\s*20)', caseSensitive: false),
    ];
    for (final p in vat20Patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        vat20 = (m.group(1) ?? '').replaceAll(',', '');
        break;
      }
    }

    // ---- VAT @ 5% ----
    String vat5 = '';
    final vat5Patterns = [
      RegExp(r'(?:vat\s*@?\s*5\.?0?0?%|5\.?0?0?%\s*vat)[^\d]{0,15}([\d,]+\.?\d{0,2})', caseSensitive: false),
    ];
    for (final p in vat5Patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        vat5 = (m.group(1) ?? '').replaceAll(',', '');
        break;
      }
    }

    // ---- Zero Rated / Exempt ----
    String zeroRated = '';
    final zeroPatterns = [
      RegExp(r'(?:zero\s*rated|exempt|zero-rated)[^\d]{0,20}([\d,]+\.?\d{0,2})', caseSensitive: false),
    ];
    for (final p in zeroPatterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        zeroRated = (m.group(1) ?? '').replaceAll(',', '');
        break;
      }
    }

    // ---- Total ----
    String total = '';
    final totalPatterns = [
      RegExp(r'(?:total\s*invoice\s*value|grand\s*total|amount\s*due|balance\s*due|total)[^\d]{0,25}([\d,]+\.?\d{0,2})', caseSensitive: false),
      RegExp(r'([\d,]+\.\d{2})\s*(?:total|due)', caseSensitive: false),
    ];
    for (final p in totalPatterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        total = (m.group(1) ?? '').replaceAll(',', '');
        break;
      }
    }

    // ---- Brief Description ----
    String description = '';
    // Prefer lines that look like work descriptions
    final descCandidates = <String>[];
    for (final line in lines) {
      if (line.length < 8 || line.length > 80) continue;
      if (RegExp(r'replace|repair|service|battery|labour|parts|oil|filter|brake|tyre|tire|diagnostic', caseSensitive: false).hasMatch(line)) {
        descCandidates.add(line);
      }
    }
    if (descCandidates.isNotEmpty) {
      description = descCandidates.take(2).join(' + ');
      if (description.length > 80) description = '${description.substring(0, 77)}...';
    } else if (lines.length > 5) {
      // Fallback: short middle snippet
      description = lines.skip(3).take(2).join(' ').replaceAll(RegExp(r'\s+'), ' ');
      if (description.length > 60) description = '${description.substring(0, 57)}...';
    }

    return OcrResult(
      rawText: text,
      date: date,
      supplier: supplier,
      net: net,
      vat20: vat20,
      vat5: vat5,
      zeroRated: zeroRated,
      total: total,
      currency: currency,
      description: description,
    );
  }

  void dispose() {
    _recognizer.close();
  }
}
