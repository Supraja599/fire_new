import 'dart:convert';

import 'package:hive/hive.dart';

class ModuleCacheService {
  static const String _boxName = 'inspectionBox';
  static const String _pendingInspectionsKey = 'pending_module_inspections';

  static Box<dynamic>? get _box =>
      Hive.isBoxOpen(_boxName) ? Hive.box<dynamic>(_boxName) : null;

  static String _cacheKey(String moduleCode, String section) =>
      'module_cache_${moduleCode}_$section';

  static dynamic _decode(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return jsonDecode(value);
      } catch (_) {
        return null;
      }
    }
    return value;
  }

  static Future<void> saveSection(
    String moduleCode,
    String section,
    dynamic data,
  ) async {
    final box = _box;
    if (box == null) return;
    await box.put(_cacheKey(moduleCode, section), jsonEncode(data));
  }

  static List<Map<String, dynamic>> getSectionList(
    String moduleCode,
    String section,
  ) {
    final decoded = _decode(_box?.get(_cacheKey(moduleCode, section)));
    if (decoded is List) {
      return decoded
          .whereType<dynamic>()
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    return [];
  }

  static Map<String, dynamic> getSectionMap(String moduleCode, String section) {
    final decoded = _decode(_box?.get(_cacheKey(moduleCode, section)));
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return <String, dynamic>{};
  }

  static Future<void> saveEquipmentList(
    String moduleCode,
    List<Map<String, dynamic>> items,
  ) {
    return saveSection(moduleCode, 'equipment', items);
  }

  static List<Map<String, dynamic>> getEquipmentList(String moduleCode) {
    return getSectionList(moduleCode, 'equipment');
  }

  static Map<String, dynamic>? findEquipment(
    String moduleCode,
    String query,
  ) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return null;

    for (final item in getEquipmentList(moduleCode)) {
      final values = [
        item['sos_code'],
        item['serial_number'],
        item['id'],
        item['equipment_id'],
      ].map((value) => value?.toString().toLowerCase() ?? '');

      if (values.any((value) => value == trimmed)) {
        return item;
      }
    }

    return null;
  }

  static List<Map<String, dynamic>> getPendingInspections() {
    final decoded = _decode(_box?.get(_pendingInspectionsKey));
    if (decoded is List) {
      return decoded
          .whereType<dynamic>()
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    return [];
  }

  static Future<void> queueInspection(Map<String, dynamic> inspection) async {
    final box = _box;
    if (box == null) return;

    final items = getPendingInspections()..add(inspection);
    await box.put(_pendingInspectionsKey, jsonEncode(items));
  }

  static Future<void> removePendingInspection(String eventId) async {
    final box = _box;
    if (box == null) return;

    final items = getPendingInspections()
      ..removeWhere((item) => item['event_id']?.toString() == eventId);
    await box.put(_pendingInspectionsKey, jsonEncode(items));
  }
}
