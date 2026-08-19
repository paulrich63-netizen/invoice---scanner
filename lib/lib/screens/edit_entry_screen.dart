import 'dart:io';
import 'package:flutter/material.dart';
import '../models/invoice_entry.dart';

class EditEntryScreen extends StatefulWidget {
  final InvoiceEntry? existing;
  final String? initialDate;
  final String? initialSupplier;
  final String? initialNet;
  final String? initialVat20;
  final String? initialVat5;
  final String? initialZeroRated;
  final String? initialTotal;
  final String? initialCurrency;
  final String? initialDescription;
  final String? initialImagePath;
  final String? rawText;
  final String? forcedId;

  const EditEntryScreen({
    super.key,
    this.existing,
    this.initialDate,
    this.initialSupplier,
    this.initialNet,
    this.initialVat20,
    this.initialVat5,
    this.initialZeroRated,
    this.initialTotal,
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
  late final TextEditingController _supplierCtrl;
  late final TextEditingController _netCtrl;
  late final TextEditingController _vat20Ctrl;
  late final TextEditingController _vat5Ctrl;
  late final TextEditingController _zeroCtrl;
  late final TextEditingController _totalCtrl;
  late final TextEditingController _currencyCtrl;
  late final TextEditingController _descCtrl;
  bool _showRaw = false;
  late final String _imagePath;

  static const _currencies = ['GBP', 'EUR', 'USD', 'CHF', 'AUD', 'CAD'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _dateCtrl = TextEditingController(text: e?.date ?? widget.initialDate ?? '');
    _supplierCtrl = TextEditingController(text: e?.supplier ?? widget.initialSupplier ?? '');
    _netCtrl = TextEditingController(text: e?.net ?? widget.initialNet ?? '');
    _vat20Ctrl = TextEditingController(text: e?.vat20 ?? widget.initialVat20 ?? '');
    _vat5Ctrl = TextEditingController(text: e?.vat5 ?? widget.initialVat5 ?? '');
    _zeroCtrl = TextEditingController(text: e?.zeroRated ?? widget.initialZeroRated ?? '');
    _totalCtrl = TextEditingController(text: e?.total ?? widget.initialTotal ?? '');
    _currencyCtrl = TextEditingController(text: e?.currency ?? widget.initialCurrency ?? 'GBP');
    _descCtrl = TextEditingController(text: e?.description ?? widget.initialDescription ?? '');
    _imagePath = e?.imagePath ?? widget.initialImagePath ?? '';
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _supplierCtrl.dispose();
    _netCtrl.dispose();
    _vat20Ctrl.dispose();
    _vat5Ctrl.dispose();
    _zeroCtrl.dispose();
    _totalCtrl.dispose();
    _currencyCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final now = DateTime.now().toIso8601String();
    final entry = InvoiceEntry(
      id: widget.existing?.id ?? widget.forcedId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: _dateCtrl.text.trim(),
      supplier: _supplierCtrl.text.trim(),
      net: _netCtrl.text.trim(),
      vat20: _vat20Ctrl.text.trim(),
      vat5: _vat5Ctrl.text.trim(),
      zeroRated: _zeroCtrl.text.trim(),
      total: _totalCtrl.text.trim(),
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
                : 'Please check and correct the extracted values.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _dateCtrl,
            decoration: const InputDecoration(
              labelText: 'Invoice Date',
              hintText: 'DD/MM/YYYY',
              prefixIcon: Icon(Icons.calendar_today, size: 20),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _supplierCtrl,
            decoration: const InputDecoration(
              labelText: 'Supplier',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),

          // Amounts section
          Text('Amounts', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _netCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Net / VATable',
                    hintText: '0.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _totalCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Total',
                    hintText: '0.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _vat20Ctrl,
                  decoration: const InputDecoration(
                    labelText: 'VAT 20%',
                    hintText: '0.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _vat5Ctrl,
                  decoration: const InputDecoration(
                    labelText: 'VAT 5%',
                    hintText: '0.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _zeroCtrl,
            decoration: const InputDecoration(
              labelText: 'Zero Rated / Exempt',
              hintText: '0.00',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _currencies.contains(_currencyCtrl.text) ? _currencyCtrl.text : 'GBP',
            decoration: const InputDecoration(
              labelText: 'Currency',
              prefixIcon: Icon(Icons.currency_exchange),
            ),
            items: _currencies
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _currencyCtrl.text = v);
            },
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description (brief)',
              hintText: 'Short description of work / goods',
              prefixIcon: Icon(Icons.notes),
              alignLabelWithHint: true,
            ),
            maxLines: 2,
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
