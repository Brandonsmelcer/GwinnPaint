import 'package:hive_flutter/hive_flutter.dart';

import '../models/saved_estimate_record.dart';

/// Local Hive persistence for saved client estimates.
abstract final class EstimateStorageService {
  static const _boxName = 'saved_estimates';

  static Box<dynamic>? _box;

  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  static Box<dynamic> get _requireBox {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError('EstimateStorageService.init() must be called before use.');
    }
    return box;
  }

  static Future<void> save(SavedEstimateRecord record) async {
    await _requireBox.put(record.id, record.toMap());
  }

  static Future<void> delete(String id) async {
    await _requireBox.delete(id);
  }

  static SavedEstimateRecord? getById(String id) {
    final raw = _requireBox.get(id);
    if (raw == null) return null;
    return SavedEstimateRecord.fromMap(Map<dynamic, dynamic>.from(raw as Map));
  }

  static List<SavedEstimateRecord> getAll() {
    return _requireBox.values
        .map((raw) => SavedEstimateRecord.fromMap(Map<dynamic, dynamic>.from(raw as Map)))
        .toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }
}
