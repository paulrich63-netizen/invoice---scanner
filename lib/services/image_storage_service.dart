import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Copies a temporary camera/gallery image into a permanent app directory
/// and returns the new absolute path.
class ImageStorageService {
  Future<String> saveInvoiceImage(File source, String entryId) async {
    final dir = await getApplicationDocumentsDirectory();
    final invoicesDir = Directory(p.join(dir.path, 'invoice_images'));
    if (!await invoicesDir.exists()) {
      await invoicesDir.create(recursive: true);
    }

    final ext = p.extension(source.path).isNotEmpty
        ? p.extension(source.path)
        : '.jpg';
    final destPath = p.join(invoicesDir.path, '$entryId$ext');
    final dest = await source.copy(destPath);
    return dest.path;
  }

  Future<void> deleteImage(String imagePath) async {
    if (imagePath.isEmpty) return;
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> imageExists(String imagePath) async {
    if (imagePath.isEmpty) return false;
    return File(imagePath).exists();
  }
}
