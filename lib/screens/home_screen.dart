import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../models/invoice_entry.dart';
import '../services/storage_service.dart';
import '../services/ocr_service.dart';
import '../services/csv_service.dart';
import '../services/excel_service.dart';
import '../services/image_storage_service.dart';
import 'edit_entry_screen.dart';

class HomeScreen extends StatefulWidget {
  final Future<void> Function(ThemeMode) onThemeChanged;
  final ThemeMode currentTheme;

  const HomeScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  final OcrService _ocr = OcrService();
  final CsvService _csv = CsvService();
  final ExcelService _excel = ExcelService();
  final ImageStorageService _images = ImageStorageService();
  final ImagePicker _picker = ImagePicker();

  List<InvoiceEntry> _entries = [];
  List<InvoiceEntry> _filtered = [];
  bool _loading = true;
  bool _processing = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _ocr.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _storage.loadEntries();
    setState(() {
      _entries = list;
      _applyFilter();
      _loading = false;
    });
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List.from(_entries);
      } else {
        _filtered = _entries.where((e) {
          return e.supplier.toLowerCase().contains(q) ||
              e.date.contains(q) ||
              e.description.toLowerCase().contains(q) ||
              e.total.contains(q);
        }).toList();
      }
    });
  }

  Future<bool> _ensurePermissions() async {
    final camera = await Permission.camera.request();
    final photos = await Permission.photos.request();
    await Permission.storage.request();
    return camera.isGranted || photos.isGranted;
  }

  Future<void> _pickImage(ImageSource source) async {
    final ok = await _ensurePermissions();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera / gallery permission required')),
        );
      }
      return;
    }

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );
      if (picked == null) return;

      setState(() => _processing = true);

      final sourceFile = File(picked.path);
      final result = await _ocr.processImage(sourceFile);

      if (!mounted) return;

      final entryId = DateTime.now().millisecondsSinceEpoch.toString();
      final savedImagePath = await _images.saveInvoiceImage(sourceFile, entryId);

      final saved = await Navigator.of(context).push<InvoiceEntry>(
        MaterialPageRoute(
          builder: (_) => EditEntryScreen(
            initialDate: result.date,
            initialSupplier: result.supplier,
            initialNet: result.net,
            initialVat20: result.vat20,
            initialVat5: result.vat5,
            initialZeroRated: result.zeroRated,
            initialTotal: result.total,
            initialCurrency: result.currency,
            initialDescription: result.description,
            initialImagePath: savedImagePath,
            rawText: result.rawText,
            forcedId: entryId,
          ),
        ),
      );

      if (saved != null) {
        await _storage.addEntry(saved);
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invoice saved'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        await _images.deleteImage(savedImagePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _showPreviewAndExport(String format) async {
    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No invoices to export')),
      );
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        'Preview (${_entries.length} invoices)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('Export ${format.toUpperCase()}'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _entries.length,
                    itemBuilder: (_, i) {
                      final e = _entries[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.supplier.isEmpty ? '(No supplier)' : e.supplier,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('${e.date}  •  Total: ${e.displayTotal}'),
                              if (e.net.isNotEmpty)
                                Text('Net: ${e.net}  |  VAT20: ${e.vat20}  |  VAT5: ${e.vat5}  |  Zero: ${e.zeroRated}',
                                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              if (e.description.isNotEmpty)
                                Text(e.description,
                                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    try {
      late final File file;
      if (format == 'xlsx') {
        file = await _excel.exportToExcel(_entries);
      } else {
        file = await _csv.exportToCsv(_entries);
      }
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Invoices export',
        subject: 'Invoices ${format.toUpperCase()}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _showExportSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Export invoices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('CSV (Excel compatible)'),
              subtitle: const Text('Preview first, then share'),
              onTap: () {
                Navigator.pop(ctx);
                _showPreviewAndExport('csv');
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_on_rounded),
              title: const Text('Excel (.xlsx)'),
              subtitle: const Text('Preview first, then share'),
              onTap: () {
                Navigator.pop(ctx);
                _showPreviewAndExport('xlsx');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(InvoiceEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete invoice?'),
        content: Text(
          '${entry.supplier.isEmpty ? "(No supplier)" : entry.supplier}\n'
          '${entry.date.isEmpty ? "—" : entry.date}  •  ${entry.displayTotal}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _storage.deleteEntry(entry.id);
      await _load();
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text('All invoices and their photos will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _storage.clearAll();
      await _load();
    }
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System default'),
              value: ThemeMode.system,
              groupValue: widget.currentTheme,
              onChanged: (v) {
                if (v != null) widget.onThemeChanged(v);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: widget.currentTheme,
              onChanged: (v) {
                if (v != null) widget.onThemeChanged(v);
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: widget.currentTheme,
              onChanged: (v) {
                if (v != null) widget.onThemeChanged(v);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export',
            onPressed: _entries.isEmpty ? null : _showExportSheet,
          ),
          IconButton(
            icon: Icon(
              widget.currentTheme == ThemeMode.dark
                  ? Icons.dark_mode
                  : widget.currentTheme == ThemeMode.light
                      ? Icons.light_mode
                      : Icons.brightness_auto,
            ),
            tooltip: 'Theme',
            onPressed: _showThemePicker,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'clear') _clearAll();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'clear', child: Text('Clear all data')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_entries.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search supplier, date, description…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchCtrl.clear(),
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filtered.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final e = _filtered[index];
                                return _InvoiceCard(
                                  entry: e,
                                  onTap: () async {
                                    final updated = await Navigator.of(context).push<InvoiceEntry>(
                                      MaterialPageRoute(
                                        builder: (_) => EditEntryScreen(existing: e),
                                      ),
                                    );
                                    if (updated != null) {
                                      final list = await _storage.loadEntries();
                                      final idx = list.indexWhere((x) => x.id == e.id);
                                      if (idx >= 0) {
                                        list[idx] = updated;
                                        await _storage.saveEntries(list);
                                        await _load();
                                      }
                                    }
                                  },
                                  onDelete: () => _delete(e),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
          if (_processing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: cs.primary),
                        const SizedBox(height: 20),
                        Text('Running OCR…', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('Extracting invoice fields', style: TextStyle(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _processing
            ? null
            : () {
                showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Icon(Icons.camera_alt, color: cs.onPrimaryContainer),
                          ),
                          title: const Text('Take photo'),
                          onTap: () {
                            Navigator.pop(ctx);
                            _pickImage(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: cs.secondaryContainer,
                            child: Icon(Icons.photo_library, color: cs.onSecondaryContainer),
                          ),
                          title: const Text('Choose from gallery'),
                          onTap: () {
                            Navigator.pop(ctx);
                            _pickImage(ImageSource.gallery);
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('Scan Invoice'),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchCtrl.text.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearch ? Icons.search_off : Icons.receipt_long_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch ? 'No matching invoices' : 'No invoices yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Try a different search term'
                  : 'Tap the button below to photograph an invoice.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final InvoiceEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _InvoiceCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasImg = entry.hasImage && File(entry.imagePath).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: hasImg
                    ? Image.file(
                        File(entry.imagePath),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(cs),
                      )
                    : _placeholder(cs),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.supplier.isEmpty ? '(No supplier)' : entry.supplier,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.date.isEmpty ? '—' : entry.date,
                      style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                    if (entry.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _chip(context, entry.displayTotal, cs.primaryContainer, cs.onPrimaryContainer, bold: true),
                        if (entry.net.isNotEmpty)
                          _chip(context, 'Net ${entry.net}', cs.secondaryContainer, cs.onSecondaryContainer),
                        if (entry.vat20.isNotEmpty)
                          _chip(context, 'VAT20 ${entry.vat20}', cs.tertiaryContainer, cs.onTertiaryContainer),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: cs.error),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Container(
      width: 56,
      height: 56,
      color: cs.primaryContainer,
      child: Icon(Icons.receipt_outlined, color: cs.onPrimaryContainer),
    );
  }

  Widget _chip(BuildContext context, String label, Color bg, Color fg, {bool bold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: fg),
      ),
    );
  }
}
