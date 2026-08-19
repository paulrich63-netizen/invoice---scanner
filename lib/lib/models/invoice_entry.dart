class InvoiceEntry {
  final String id;
  final String date;
  final String supplier;
  final String net;
  final String vat20;
  final String vat5;
  final String zeroRated;
  final String total;
  final String currency;
  final String description;
  final String createdAt;
  final String imagePath;

  InvoiceEntry({
    required this.id,
    required this.date,
    required this.supplier,
    this.net = '',
    this.vat20 = '',
    this.vat5 = '',
    this.zeroRated = '',
    required this.total,
    this.currency = 'GBP',
    required this.description,
    required this.createdAt,
    this.imagePath = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'supplier': supplier,
        'net': net,
        'vat20': vat20,
        'vat5': vat5,
        'zeroRated': zeroRated,
        'total': total,
        'currency': currency,
        'description': description,
        'createdAt': createdAt,
        'imagePath': imagePath,
      };

  factory InvoiceEntry.fromJson(Map<String, dynamic> json) {
    return InvoiceEntry(
      id: (json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
      date: (json['date'] ?? '').toString(),
      supplier: (json['supplier'] ?? '').toString(),
      net: (json['net'] ?? '').toString(),
      vat20: (json['vat20'] ?? '').toString(),
      vat5: (json['vat5'] ?? '').toString(),
      zeroRated: (json['zeroRated'] ?? '').toString(),
      total: (json['total'] ?? '').toString(),
      currency: (json['currency'] ?? 'GBP').toString(),
      description: (json['description'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
      imagePath: (json['imagePath'] ?? '').toString(),
    );
  }

  InvoiceEntry copyWith({
    String? date,
    String? supplier,
    String? net,
    String? vat20,
    String? vat5,
    String? zeroRated,
    String? total,
    String? currency,
    String? description,
    String? imagePath,
  }) {
    return InvoiceEntry(
      id: id,
      date: date ?? this.date,
      supplier: supplier ?? this.supplier,
      net: net ?? this.net,
      vat20: vat20 ?? this.vat20,
      vat5: vat5 ?? this.vat5,
      zeroRated: zeroRated ?? this.zeroRated,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      createdAt: createdAt,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  bool get hasImage => imagePath.isNotEmpty;

  String get displayTotal {
    if (total.isEmpty) return '—';
    return currency.isNotEmpty ? '$total $currency' : total;
  }

  String get displayNet {
    if (net.isEmpty) return '—';
    return currency.isNotEmpty ? '$net $currency' : net;
  }
}
