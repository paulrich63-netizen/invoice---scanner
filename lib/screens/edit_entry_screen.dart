import 'dart:io';
import 'package:flutter/material.dart';
import '../models/invoice_entry.dart';

class EditEntryScreen extends StatefulWidget {
  final InvoiceEntry? existing;
  final String? initialDate;
  final String? initialDueDate;
  final String? initialInvoiceNumber;
  final String? initialSupplier;
  final String? initialTotal;
  final String? initialTax;
  final String? initialCurrency;
  final String? initialDescription;
  final String? initialImagePath;
  final String? rawText;
  final String? forcedId;

  const EditEntryScreen({
    super.key,
    this.existing,
    this.initialDate,
    this.initialDueDate,
    this.initialInvoiceNumber,
    this.initialSupplier,
    this.initialTotal,
    this.initialTax,
    this.initialCurrency,
    this.initialDescription,
    this.initialImagePath,
    this.rawText,
    this.forcedId,
  });

  @override
  State<EditEntryScreen> createState() => _EditEntryScreenState();
}

class _EditEntryScreenState extends State<EditEntryScreen> {
  late final TextEditingController _dateCtrl;
  late final TextEditingController _dueDateCtrl;
  late final TextEditingController _invNumCtrl;
  late final TextEditingController _supplierCtrl;
  late final TextEditingController _totalCtrl;
  late final TextEditingController _taxCtrl;
  late final TextEditingController _currencyCtrl;
  late final TextEditingController _descCtrl;
  bool _showRaw = false;
  late final String _imagePath;

  static const _currencies = ['', 'EUR', 'USD', 'GBP', 'CHF', 'AUD', 'CAD', 'JPY'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _dateCtrl = TextEditingController(text: e?.date ?? widget.initialDate ?? '');
    _dueDateCtrl = TextEditingController(text: e?.dueDate ?? widget.initialDueDate ?? '');
    _invNumCtrl = TextEditingController(text: e?.invoiceNumber ?? widget.initialInvoiceNumber ?? '');
    _supplierCtrl = TextEditingController(text: e?.supplier ?? widget.initialSupplier ?? '');
    _totalCtrl = TextEditingController(text: e?.total ?? widget.initialTotal ?? '');
    _taxCtrl = TextEditingController(text: e?.tax ?? widget.initialTax ?? '');
    _currencyCtrl = TextEditingController(text: e?.currency ?? widget.initialCurrency ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? widget.initialDescription ?? '');
    _imagePath = e?.imagePath ?? widget.initialImagePath ?? '';
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _dueDateCtrl.dispose();
    _invNumCtrl.dispose();
    _supplierCtrl.dispose();
    _totalCtrl.dispose();
    _taxCtrl.dispose();
    _currencyCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final now = DateTime.now().toIso8601String();
    final entry = InvoiceEntry(
      id: widget.existing?.id ?? widget.forcedId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: _dateCtrl.text.trim(),
      dueDate: _dueDateCtrl.text.trim(),
      invoiceNumber: _invNumCtrl.text.trim(),
      supplier: _supplierCtrl.text.trim(),
      total: _totalCtrl.text.trim(),
      tax: _taxCtrl.text.trim(),
      currency: _currencyCtrl.text.trim().toUpperCase(),
      description: _descCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? now,
      imagePath: _imagePath,
    );
    Navigator.of(context).pop(entry);
  }

  void _openFullImage() {
    if (_imagePath.isEmpty || !File(_imagePath).existsSync()) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Invoice photo'),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(_imagePath), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final cs = Theme.of(context).colorScheme;
    final hasImg = _imagePath.isNotEmpty && File(_imagePath).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Invoice' : 'Review Extracted Data'),
        actions: [
          if (widget.rawText != null && widget.rawText!.isNotEmpty)
            IconButton(
              icon: Icon(_showRaw ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              tooltip: 'Toggle raw OCR text',
              onPressed: () => setState(() => _showRaw = !_showRaw),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Attached photo
          if (hasImg) ...[
            GestureDetector(
              onTap: _openFullImage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.file(
                    File(_imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: cs.surfaceContainerHighest,
                      child: const Center(child: Icon(Icons.broken_image, size: 48)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap photo to view full size',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
          ],

          if (_showRaw && widget.rawText != null) ...[
            Card(
              color: cs.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Raw OCR text', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    SelectableText(
                      widget.rawText!,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          Text(
            isEdit
                ? 'Edit the fields below and save.'
                : 'OCR results are pre-filled. Please correct any mistakes before saving.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _invNumCtrl,
            decoration: const InputDecoration(
              labelText: 'Invoice number',
              hintText: 'e.g. INV-2024-001',
              prefixIcon: Icon(Icons.tag),
            ),
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Invoice date',
                    hintText: 'YYYY-MM-DD',
                    prefixIcon: Icon(Icons.calendar_today, size: 20),
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _dueDateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Due date',
                    hintText: 'optional',
                    prefixIcon: Icon(Icons.event, size: 20),
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _supplierCtrl,
            decoration: const InputDecoration(
              labelText: 'Supplier / Vendor',
              hintText: 'Company name',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _totalCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Total',
                    hintText: '123.45',
                    prefixIcon: Icon(Icons.payments_outlined, size: 20),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _taxCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tax / VAT',
                    hintText: '0.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: _currencies.contains(_currencyCtrl.text) ? _currencyCtrl.text : '',
            decoration: const InputDecoration(
              labelText: 'Currency',
              prefixIcon: Icon(Icons.currency_exchange),
            ),
            items: _currencies
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.isEmpty ? '— None —' : c),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _currencyCtrl.text = v);
            },
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description / Notes',
              hintText: 'What the invoice is for',
              prefixIcon: Icon(Icons.notes),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 28),

          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded),
            label: Text(isEdit ? 'Update Invoice' : 'Save Invoice'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
