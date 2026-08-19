class InvoiceEntry {
  final String id;
  final String date;          // Invoice date only
  final String supplier;
  final String net;           // Net / VATable amount
  final String vat20;         // VAT at 20%
  final String vat5;          // VAT at 5%
  final String zeroRated;     // Zero-rated / exempt
  final String total;
  final String currency;
  final String description;   // Brief description
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

  factory InvoiceEntry.fromJson(Map<String, dynamic> json) => InvoiceEntry(
        id: json['id'] as String,
        date: json['date'] as String? ?? '',
        supplier: json['supplier'] as String? ?? '',
        net: json['net'] as String? ?? '',
        vat20: json['vat20'] as String? ?? '',
        vat5: json['vat5'] as String? ?? '',
        zeroRated: json['zeroRated'] as String? ?? '',
        total: json['total'] as String? ?? '',
        currency: json['currency'] as String? ?? 'GBP',
        description: json['description'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
        imagePath: json['imagePath'] as String? ?? '',
      );

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
