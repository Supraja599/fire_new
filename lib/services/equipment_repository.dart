import 'package:flutter/foundation.dart';
import 'package:fire_new/local_db.dart';
import 'package:fire_new/services/apiservice.dart';

class EquipmentRepository {
  final Future<Map<String, dynamic>?> Function(String) _apiSearch;
  final Future<void> Function() _apiSync;

  /// Public constructor to allow Dependency Injection and Mocking.
  /// Standard production runs use default parameters connected to ApiService.
  EquipmentRepository({
    Future<Map<String, dynamic>?> Function(String)? apiSearchOverride,
    Future<void> Function()? apiSyncOverride,
  })  : _apiSearch = apiSearchOverride ?? ApiService.searchAnyOnline,
        _apiSync = apiSyncOverride ?? ApiService.syncPendingModuleInspections;
  
  // Static fallback instance
  static final EquipmentRepository instance = EquipmentRepository();

  /// Gets a single equipment details by ID (e.g. SOS code or Serial Number).
  /// Strictly Online-First: contacts cloud server first, caches on success, and
  /// falls back to SQLite cache when offline.
  Future<Map<String, dynamic>?> getEquipment(String id) async {
    final searchId = id.trim();
    if (searchId.isEmpty) return null;

    Map<String, dynamic>? apiMatch;
    bool apiCallSucceeded = false;

    // 1. Try to fetch from cloud API globally first (Online-First)
    try {
      apiMatch = await _apiSearch(searchId);
      apiCallSucceeded = true;
    } catch (e) {
      debugPrint("EquipmentRepository online lookup failed (offline fallback active): $e");
    }

    if (apiCallSucceeded && apiMatch != null) {
      final moduleCode = LocalDB.normalizeModuleCode(apiMatch['module_code']?.toString() ?? 'fire_extinguisher');
      // Cache locally for offline availability next time
      if (moduleCode == 'fire_extinguisher') {
        await LocalDB.insert(searchId, apiMatch);
      } else {
        await LocalDB.saveSingleModuleRecord(
          moduleCode: moduleCode,
          recordType: 'equipment',
          item: apiMatch,
        );
      }
      return apiMatch;
    }

    // 2. Fallback to local SQLite DB (Offline fallback)
    final localMatch = await LocalDB.findEquipmentModuleAndData(searchId);
    if (localMatch != null) {
      final data = localMatch['data'];
      if (data is Map<String, dynamic>) {
        // Ensure data map contains module_code from the DB column if missing
        if (!data.containsKey('module_code') && localMatch.containsKey('module_code')) {
          data['module_code'] = localMatch['module_code'];
        }
        return data;
      }
    }

    return null;
  }

  /// Queues and submits an inspection report.
  /// 1. Saves locally in SQLite queue and updates cached status immediately (Offline responsiveness).
  /// 2. Fires background sync request to upload pending inspections to cloud server.
  Future<void> submitInspection({
    required String eventId,
    required String moduleCode,
    required String equipmentId,
    required String inspectorName,
    required String remarks,
    required List<Map<String, dynamic>> answers,
    required List<String> images,
  }) async {
    // 1. Queue local SQLite inspection sync
    await LocalDB.queueModuleInspection(
      eventId: eventId,
      moduleCode: moduleCode,
      equipmentId: equipmentId,
      payload: {
        "inspector_name": inspectorName,
        "remarks": remarks,
        "answers": answers,
        "images": images,
      },
    );

    // 2. Update local cached status
    await LocalDB.updateLocalEquipmentStatusAfterInspection(
      moduleCode: moduleCode,
      equipmentId: equipmentId,
    );

    // 3. Trigger async background synchronization (fire-and-forget)
    _apiSync().catchError((e) {
      debugPrint("EquipmentRepository failed to push inspection to server: $e");
    });
  }

  /// Syncs all local queued inspections (used manually or on connection changes).
  Future<void> syncAllPendingData() async {
    try {
      await _apiSync();
    } catch (e) {
      debugPrint("EquipmentRepository syncAllPendingData Error: $e");
    }
  }
}
