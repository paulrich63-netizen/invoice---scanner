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

  /// Returns true if the number looks like a realistic money amount
  bool _isMoney(String s) {
    final n = double.tryParse(s.replaceAll(',', ''));
    if (n == null) return false;
    // Reject company numbers / phone numbers / long IDs
    if (n > 100000) return false;
    if (n < 0) return false;
    // Prefer values that have decimal places or are small-medium
    return true;
  }

  String? _firstMoney(RegExp pattern, String text) {
    for (final m in pattern.allMatches(text)) {
      final raw = (m.group(1) ?? '').replaceAll(',', '');
      if (_isMoney(raw)) return raw;
    }
    return null;
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
    }

    // ---- Invoice Date ----
    String date = '';
    final datePatterns = [
      RegExp(r'(?:invoice\s*date|date)[:\s]*(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})', caseSensitive: false),
      RegExp(r'\b(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})\b'),
    ];
    for (final p in datePatterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        date = m.group(1) ?? '';
        break;
      }
    }

    // ---- Supplier ----
    String supplier = '';
    for (var i = 0; i < lines.length && i < 15; i++) {
      final line = lines[i];
      if (line.length < 5) continue;
      if (RegExp(
              r'invoice|receipt|tax|date|total|amount|page|tel|phone|www\.|@|vat\s*number|customer|order|labour|parts|quantity|rate|net|vehicle|make|mileage|technician|thank',
              caseSensitive: false)
          .hasMatch(line)) continue;
      if (RegExp(r'[A-Za-z]{4,}').hasMatch(line) && !RegExp(r'^\d').hasMatch(line)) {
        supplier = line;
        if (RegExp(r'\b(Ltd|Limited|PLC|LLP|Inc|LLC)\b', caseSensitive: false).hasMatch(line)) {
          break;
        }
      }
    }

    // ---- Total (prefer "Total Invoice Value") ----
    String total = '';
    final totalPatterns = [
      RegExp(r'total\s*invoice\s*value[^\d]{0,20}([\d,]+\.\d{2})', caseSensitive: false),
      RegExp(r'(?:grand\s*total|amount\s*due|balance\s*due)[^\d]{0,20}([\d,]+\.\d{2})', caseSensitive: false),
      RegExp(r'total[^\d]{0,15}([\d,]+\.\d{2})', caseSensitive: false),
    ];
    for (final p in totalPatterns) {
      final v = _firstMoney(p, text);
      if (v != null) {
        total = v;
        break;
      }
    }

    // ---- Net / Vatable Items ----
    String net = '';
    final netPatterns = [
      RegExp(r'vatable\s*items[^\d]{0,20}([\d,]+\.\d{2})', caseSensitive: false),
      RegExp(r'(?:net\s*(?:amount|total)?|sub\s*total|goods)[^\d]{0,20}([\d,]+\.\d{2})', caseSensitive: false),
    ];
    for (final p in netPatterns) {
      final v = _firstMoney(p, text);
      if (v != null) {
        net = v;
        break;
      }
    }

    // ---- VAT @ 20% ----
    String vat20 = '';
    final vat20Patterns = [
      RegExp(r'vat\s*@?\s*20\.?0?0?\s*%[^\d]{0,15}([\d,]+\.\d{2})', caseSensitive: false),
      RegExp(r'20\.?0?0?\s*%\s*vat[^\d]{0,15}([\d,]+\.\d{2})', caseSensitive: false),
    ];
    for (final p in vat20Patterns) {
      final v = _firstMoney(p, text);
      if (v != null) {
        vat20 = v;
        break;
      }
    }

    // ---- VAT @ 5% ----
    String vat5 = '';
    final vat5Patterns = [
      RegExp(r'vat\s*@?\s*5\.?0?0?\s*%[^\d]{0,15}([\d,]+\.\d{2})', caseSensitive: false),
      RegExp(r'5\.?0?0?\s*%\s*vat[^\d]{0,15}([\d,]+\.\d{2})', caseSensitive: false),
    ];
    for (final p in vat5Patterns) {
      final v = _firstMoney(p, text);
      if (v != null) {
        vat5 = v;
        break;
      }
    }

    // ---- Zero Rated / Exempt ----
    String zeroRated = '';
    final zeroPatterns = [
      RegExp(r'(?:zero\s*rated|zero-rated|exempt)[^\d]{0,20}([\d,]+\.\d{2})', caseSensitive: false),
    ];
    for (final p in zeroPatterns) {
      final v = _firstMoney(p, text);
      if (v != null) {
        zeroRated = v;
        break;
      }
    }

    // ---- Brief Description ----
    String description = '';
    final descCandidates = <String>[];
    for (final line in lines) {
      if (line.length < 8 || line.length > 90) continue;
      if (RegExp(r'replace|repair|service|battery|labour|parts|oil|filter|brake|tyre|tire|diagnostic|erase|fault|road\s*test',
              caseSensitive: false)
          .hasMatch(line)) {
        descCandidates.add(line);
      }
    }
    if (descCandidates.isNotEmpty) {
      description = descCandidates.take(2).join(' + ');
      if (description.length > 90) description = '${description.substring(0, 87)}...';
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
