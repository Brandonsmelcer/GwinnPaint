import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Result of importing a floor-plan image for on-site reference.
class BlueprintImportResult {
  const BlueprintImportResult({
    this.fileName,
    this.filePath,
    this.base64Data,
    this.isPdf = false,
  });

  final String? fileName;
  final String? filePath;
  final String? base64Data;
  final bool isPdf;

  bool get hasPreview => filePath != null || base64Data != null;
}

/// Handles free, local-only blueprint / floor-plan file import.
abstract final class BlueprintService {
  static const _allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'pdf'];

  static Future<BlueprintImportResult?> pickAndSave() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      withData: kIsWeb,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final ext = (file.extension ?? 'jpg').toLowerCase();
    final isPdf = ext == 'pdf';
    final storedName = '${DateTime.now().millisecondsSinceEpoch}.$ext';

    if (kIsWeb) {
      if (file.bytes == null) return null;
      return BlueprintImportResult(
        fileName: storedName,
        base64Data: base64Encode(file.bytes!),
        isPdf: isPdf,
      );
    }

    if (file.path == null) return null;

    final blueprintsDir = await _blueprintsDirectory();
    final destPath = p.join(blueprintsDir.path, storedName);
    await File(file.path!).copy(destPath);

    return BlueprintImportResult(
      fileName: storedName,
      filePath: destPath,
      isPdf: isPdf,
    );
  }

  static Future<File?> resolveFile(String? fileName) async {
    if (fileName == null || kIsWeb) return null;
    final path = p.join((await _blueprintsDirectory()).path, fileName);
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  static Uint8List? decodeBase64(String? data) {
    if (data == null || data.isEmpty) return null;
    try {
      return base64Decode(data);
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteFile(String? fileName) async {
    if (fileName == null || kIsWeb) return;
    final file = await resolveFile(fileName);
    if (file != null && file.existsSync()) {
      await file.delete();
    }
  }

  static Future<Directory> _blueprintsDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'blueprints'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
