import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice_entry.dart';
import 'image_storage_service.dart';

class StorageService {
  static const _key = 'invoice_entries';
  final ImageStorageService _images = ImageStorageService();

  Future<List<InvoiceEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((e) => InvoiceEntry.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveEntries(List<InvoiceEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = entries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, raw);
  }

  Future<void> addEntry(InvoiceEntry entry) async {
    final list = await loadEntries();
    list.insert(0, entry);
    await saveEntries(list);
  }

  Future<void> deleteEntry(String id) async {
    final list = await loadEntries();
    final entry = list.cast<InvoiceEntry?>().firstWhere(
          (e) => e?.id == id,
          orElse: () => null,
        );
    if (entry != null && entry.hasImage) {
      await _images.deleteImage(entry.imagePath);
    }
    list.removeWhere((e) => e.id == id);
    await saveEntries(list);
  }

  Future<void> clearAll() async {
    final list = await loadEntries();
    for (final e in list) {
      if (e.hasImage) await _images.deleteImage(e.imagePath);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
