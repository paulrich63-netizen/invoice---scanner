class InvoiceEntry {
  final String id;
  final String date;
  final String dueDate;
  final String invoiceNumber;
  final String supplier;
  final String total;
  final String tax;
  final String currency;
  final String description;
  final String createdAt;
  final String imagePath; // absolute path to the saved invoice photo

  InvoiceEntry({
    required this.id,
    required this.date,
    this.dueDate = '',
    this.invoiceNumber = '',
    required this.supplier,
    required this.total,
    this.tax = '',
    this.currency = '',
    required this.description,
    required this.createdAt,
    this.imagePath = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'dueDate': dueDate,
        'invoiceNumber': invoiceNumber,
        'supplier': supplier,
        'total': total,
        'tax': tax,
        'currency': currency,
        'description': description,
        'createdAt': createdAt,
        'imagePath': imagePath,
      };

  factory InvoiceEntry.fromJson(Map<String, dynamic> json) => InvoiceEntry(
        id: json['id'] as String,
        date: json['date'] as String? ?? '',
        dueDate: json['dueDate'] as String? ?? '',
        invoiceNumber: json['invoiceNumber'] as String? ?? '',
        supplier: json['supplier'] as String? ?? '',
        total: json['total'] as String? ?? '',
        tax: json['tax'] as String? ?? '',
        currency: json['currency'] as String? ?? '',
        description: json['description'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
        imagePath: json['imagePath'] as String? ?? '',
      );

  InvoiceEntry copyWith({
    String? date,
    String? dueDate,
    String? invoiceNumber,
    String? supplier,
    String? total,
    String? tax,
    String? currency,
    String? description,
    String? imagePath,
  }) {
    return InvoiceEntry(
      id: id,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      supplier: supplier ?? this.supplier,
      total: total ?? this.total,
      tax: tax ?? this.tax,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      createdAt: createdAt,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  String get displayTotal {
    if (total.isEmpty) return '—';
    final c = currency.isNotEmpty ? ' $currency' : '';
    return '$total$c';
  }

  bool get hasImage => imagePath.isNotEmpty;
}
