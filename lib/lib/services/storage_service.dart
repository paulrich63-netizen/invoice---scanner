import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice_entry.dart';
import 'image_storage_service.dart';

class StorageService {
  static const _key = 'invoice_entries';
  final ImageStorageService _images = ImageStorageService();

  Future<List<InvoiceEntry>> loadEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key) ?? [];
      final list = <InvoiceEntry>[];
      for (final item in raw) {
        try {
          final map = jsonDecode(item) as Map<String, dynamic>;
          list.add(InvoiceEntry.fromJson(map));
        } catch (_) {
          // skip corrupted entries
        }
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return [];
    }
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
    InvoiceEntry? toDelete;
    for (final e in list) {
      if (e.id == id) {
        toDelete = e;
        break;
      }
    }
    if (toDelete != null && toDelete.hasImage) {
      await _images.deleteImage(toDelete.imagePath);
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
