import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDB {
  static Database? _db;

  @visibleForTesting
  static set database(Database? db) => _db = db;

  static String normalizeModuleCode(String code) {
    final c = code.trim().toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    switch (c) {
      case 'fireextinguisher':
      case 'extinguishers':
      case 'extinguisher':
        return 'fire_extinguisher';
      case 'hosereel':
      case 'hosereels':
      case 'hose_reel':
        return 'hose_reel';
      case 'sprinkler':
      case 'sprinklers':
      case 'splinker':
      case 'splinkers':
        return 'sprinkler';
      case 'hydrant':
      case 'hydrants':
        return 'hydrant';
      case 'firealarm':
      case 'alarmpanel':
      case 'alarmpanels':
      case 'fire_alarm':
        return 'fire_alarm';
      case 'smokedetector':
      case 'smokedetectors':
        return 'smoke_detector';
      case 'firetrolley':
      case 'firetrolleys':
        return 'fire_trolley';
      case 'exitsign':
      case 'exitsigns':
      case 'emergencyexit':
      case 'emergencyexits':
        return 'exit_sign';
      case 'emergencylight':
      case 'emergencylighting':
      case 'emergencylights':
        return 'emergency_light';
      case 'pasystem':
      case 'pasystems':
        return 'pa_system';
      case 'windsock':
      case 'windsocks':
        return 'wind_sock';
      case 'scbaunit':
      case 'scbaunits':
        return 'scba_unit';
      case 'ambulance':
      case 'ambulances':
        return 'ambulance';
      case 'firstaidkit':
      case 'firstaid':
      case 'firstaidkits':
        return 'first_aid_kit';
      case 'safetyshower':
      case 'emergencyshower':
      case 'emergencyshowers':
      case 'chemicalshower':
      case 'chemicalshowers':
        return 'safety_shower';
      case 'eyewashstation':
      case 'eyewash':
      case 'eyewashstations':
        return 'eyewash_station';
      case 'spillkit':
      case 'spillkits':
        return 'spill_kit';
      case 'ppestation':
      case 'ppecabinets':
      case 'ppecabinet':
      case 'ppecabs':
      case 'ppestations':
        return 'ppe_station';
      case 'suppressionsystem':
      case 'co2system':
      case 'co2systems':
        return 'suppression_system';
      case 'signage':
      case 'signages':
        return 'signage';
      case 'emergencycomm':
      case 'emergencycomms':
        return 'emergency_comm';
      case 'fireblanket':
      case 'fireblankets':
        return 'fire_blanket';
      case 'musterpoint':
      case 'musterpoints':
        return 'muster_point';
      case 'heatdetector':
      case 'heatdetectors':
        return 'heat_detector';
      case 'codetector':
      case 'codetectors':
        return 'co_detector';
      case 'firedoor':
      case 'firedoors':
        return 'fire_door';
      default:
        return code;
    }
  }

  static Future<void> migrateModuleCodes(Database db) async {
    final Map<String, String> migrations = {
      'hosereel': 'hose_reel',
      'sprinklers': 'sprinkler',
      'splinkers': 'sprinkler',
      'spill_kits': 'spill_kit',
      'scba_units': 'scba_unit',
      'ppe_cabinets': 'ppe_station',
      'co2_system': 'suppression_system',
      'fire_blankets': 'fire_blanket',
      'muster_points': 'muster_point',
      'alarm_panel': 'fire_alarm',
      'emergency_exits': 'exit_sign',
      'emergency_lighting': 'emergency_light',
      'first_aid': 'first_aid_kit',
      'emergency_shower': 'safety_shower',
      'chemical_shower': 'safety_shower',
      'chemical_showers': 'safety_shower',
      'chemicalshower': 'safety_shower',
      'eye_wash': 'eyewash_station',
    };

    for (final entry in migrations.entries) {
      await db.update(
        'module_records',
        {'module_code': entry.value},
        where: 'module_code = ?',
        whereArgs: [entry.key],
      );
      await db.update(
        'pending_module_sync',
        {'module_code': entry.value},
        where: 'module_code = ?',
        whereArgs: [entry.key],
      );
    }
  }

  static Future<Database> get database async {
    if (_db != null) return _db!;
    if (kIsWeb) {
      throw UnsupportedError("sqflite (LocalDB) is not supported on Web. Please run on Android or Windows.");
    }
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'app.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS module_records (
              module_code TEXT,
              record_type TEXT,
              record_id TEXT,
              data TEXT,
              PRIMARY KEY (module_code, record_type, record_id)
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS pending_module_sync (
              event_id TEXT PRIMARY KEY,
              module_code TEXT,
              equipment_id TEXT,
              payload TEXT,
              isSynced INTEGER
            )
          ''');
        }
      },
      onOpen: (db) async {
        await db.execute('CREATE TABLE IF NOT EXISTS extinguishers (id TEXT PRIMARY KEY, data TEXT)');
        await db.execute('CREATE TABLE IF NOT EXISTS pending_sync (id TEXT PRIMARY KEY, data TEXT, isSynced INTEGER)');
        await db.execute('CREATE TABLE IF NOT EXISTS module_records (module_code TEXT, record_type TEXT, record_id TEXT, data TEXT, PRIMARY KEY (module_code, record_type, record_id))');
        await db.execute('CREATE TABLE IF NOT EXISTS pending_module_sync (event_id TEXT PRIMARY KEY, module_code TEXT, equipment_id TEXT, payload TEXT, isSynced INTEGER)');
        await db.execute('CREATE TABLE IF NOT EXISTS user_session (username TEXT PRIMARY KEY, password TEXT, token TEXT, role TEXT, last_login TEXT)');
        await migrateModuleCodes(db);
      },
    );
  }

  static Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE extinguishers (
        id TEXT PRIMARY KEY,
        data TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_sync (
        id TEXT PRIMARY KEY,
        data TEXT,
        isSynced INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE module_records (
        module_code TEXT,
        record_type TEXT,
        record_id TEXT,
        data TEXT,
        PRIMARY KEY (module_code, record_type, record_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_module_sync (
        event_id TEXT PRIMARY KEY,
        module_code TEXT,
        equipment_id TEXT,
        payload TEXT,
        isSynced INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE user_session (
        username TEXT PRIMARY KEY,
        password TEXT,
        token TEXT,
        role TEXT,
        last_login TEXT
      )
    ''');
  }

  static Future<void> insert(String id, Map<String, dynamic> data) async {
    if (kIsWeb) return;
    final db = await database;

    await db.insert(
      'extinguishers',
      {
        'id': id,
        'data': jsonEncode(data),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> saveAllExtinguishers(List<Map<String, dynamic>> items) async {
    if (kIsWeb) return;
    final db = await database;
    final batch = db.batch();

    for (var item in items) {
      final id = item['id']?.toString() ?? '';
      if (id.trim().isEmpty) continue;

      final normalizedId = id.trim().replaceAll("\n", "").replaceAll(" ", "").replaceAll("-", "").toUpperCase();

      batch.insert(
        'extinguishers',
        {
          'id': normalizedId,
          'data': jsonEncode(item),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  static Future<Map<String, dynamic>?> get(String id) async {
    if (kIsWeb) return null;
    final db = await database;

    // 1. Try extinguishers table first (legacy)
    final result = await db.query(
      'extinguishers',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return jsonDecode(result.first['data'] as String);
    }

    // 2. Try module_records table (all other modules)
    final trimmed = id.trim().toLowerCase();
    
    // FAST PATH: Direct query by record_id (indexed primary key search)
    final fastResult = await db.query(
      'module_records',
      where: 'record_id = ?',
      whereArgs: [trimmed],
      limit: 1,
    );

    if (fastResult.isNotEmpty) {
      return jsonDecode(fastResult.first['data'] as String);
    }

    // SLOW PATH (Fallback): Scan only if direct ID lookup misses
    final moduleResult = await db.query('module_records');

    for (final row in moduleResult) {
      final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      final values = [
        data['sos_code'],
        data['serial_number'],
        data['id'],
        data['equipment_id'],
      ].map((v) => v?.toString().toLowerCase() ?? '');

      if (values.contains(trimmed)) {
        return data;
      }
    }

    return null;
  }

  static Future<List<Map<String, dynamic>>> getAllEquipmentGlobal() async {
    if (kIsWeb) return [];
    final db = await database;
    
    // Get extinguishers
    final extRows = await db.query('extinguishers');
    final exts = extRows.map((row) => Map<String, dynamic>.from(jsonDecode(row['data'] as String))).toList();

    // Get all other module equipment
    final modRows = await db.query(
      'module_records',
      where: 'record_type = ?',
      whereArgs: ['equipment'],
    );
    final mods = modRows.map((row) => Map<String, dynamic>.from(jsonDecode(row['data'] as String))).toList();

    return [...exts, ...mods];
  }

  static Future<List<String>> getAllIds() async {
    if (kIsWeb) return [];
    final db = await database;
    final result = await db.query('extinguishers');
    return result.map((e) => e['id'].toString()).toList();
  }

  static Future<List<Map<String, dynamic>>> getAllExtinguishers() async {
    if (kIsWeb) return [];
    final db = await database;
    final result = await db.query('extinguishers');
    return result.map((row) => Map<String, dynamic>.from(jsonDecode(row['data'] as String))).toList();
  }

  static Future<void> insertPending(String id, String data) async {
    if (kIsWeb) return;
    final db = await database;

    await db.insert(
      'pending_sync',
      {
        'id': id,
        'data': data,
        'isSynced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getPending() async {
    if (kIsWeb) return [];
    final db = await database;
    return db.query(
      'pending_sync',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
  }

  static Future<void> markSynced(String id) async {
    if (kIsWeb) return;
    final db = await database;

    await db.update(
      'pending_sync',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> saveModuleRecords({
    required String moduleCode,
    required String recordType,
    required List<Map<String, dynamic>> items,
  }) async {
    if (kIsWeb) return;
    final db = await database;
    final batch = db.batch();
    final normCode = normalizeModuleCode(moduleCode);

    batch.delete(
      'module_records',
      where: 'module_code = ? AND record_type = ?',
      whereArgs: [normCode, recordType],
    );

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final recordId = (item['id'] ??
              item['sos_code'] ??
              item['serial_number'] ??
              '${recordType}_$i')
          .toString();

      batch.insert(
        'module_records',
        {
          'module_code': normCode,
          'record_type': recordType,
          'record_id': recordId,
          'data': jsonEncode(item),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  static Future<void> saveSingleModuleRecord({
    required String moduleCode,
    required String recordType,
    required Map<String, dynamic> item,
  }) async {
    if (kIsWeb) return;
    final db = await database;
    final normCode = normalizeModuleCode(moduleCode);
    final recordId = (item['id'] ??
            item['sos_code'] ??
            item['serial_number'] ??
            'unknown')
        .toString();

    await db.insert(
      'module_records',
      {
        'module_code': normCode,
        'record_type': recordType,
        'record_id': recordId,
        'data': jsonEncode(item),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (recordType == 'equipment' && recordId != 'unknown') {
      await insertPending(recordId, jsonEncode(item));
    }
  }

  static Future<List<Map<String, dynamic>>> getModuleRecords({
    required String moduleCode,
    required String recordType,
  }) async {
    if (kIsWeb) return [];
    try {
      final db = await database;
      final normCode = normalizeModuleCode(moduleCode);
      final result = await db.query(
        'module_records',
        where: 'module_code = ? AND record_type = ?',
        whereArgs: [normCode, recordType],
      );

      return result
          .map((row) => Map<String, dynamic>.from(jsonDecode(row['data'] as String)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveModuleMap({
    required String moduleCode,
    required String recordType,
    required Map<String, dynamic> data,
  }) async {
    if (kIsWeb) return;
    final db = await database;
    final normCode = normalizeModuleCode(moduleCode);
    await db.insert(
      'module_records',
      {
        'module_code': normCode,
        'record_type': recordType,
        'record_id': 'single',
        'data': jsonEncode(data),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, dynamic>> getModuleMap({
    required String moduleCode,
    required String recordType,
  }) async {
    if (kIsWeb) return <String, dynamic>{};
    try {
      final db = await database;
      final normCode = normalizeModuleCode(moduleCode);
      final result = await db.query(
        'module_records',
        where: 'module_code = ? AND record_type = ? AND record_id = ?',
        whereArgs: [normCode, recordType, 'single'],
        limit: 1,
      );

      if (result.isEmpty) return <String, dynamic>{};
      return Map<String, dynamic>.from(jsonDecode(result.first['data'] as String));
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static Future<Map<String, dynamic>?> findModuleEquipment({
    required String moduleCode,
    required String query,
  }) async {
    final normCode = normalizeModuleCode(moduleCode);
    final items = await getModuleRecords(
      moduleCode: normCode,
      recordType: 'equipment',
    );
    final trimmed = query.trim().toLowerCase();

    for (final item in items) {
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

  static Future<void> queueModuleInspection({
    required String eventId,
    required String moduleCode,
    required String equipmentId,
    required Map<String, dynamic> payload,
  }) async {
    if (kIsWeb) return;
    final db = await database;
    final normCode = normalizeModuleCode(moduleCode);
    await db.insert(
      'pending_module_sync',
      {
        'event_id': eventId,
        'module_code': normCode,
        'equipment_id': equipmentId,
        'payload': jsonEncode(payload),
        'isSynced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getPendingModuleInspections({
    String? moduleCode,
  }) async {
    if (kIsWeb) return [];
    final db = await database;
    final normCode = moduleCode != null ? normalizeModuleCode(moduleCode) : null;
    final result = await db.query(
      'pending_module_sync',
      where: normCode == null ? 'isSynced = ?' : 'isSynced = ? AND module_code = ?',
      whereArgs: normCode == null ? [0] : [0, normCode],
    );

    return result
        .map(
          (row) => {
            'event_id': row['event_id'],
            'module_code': row['module_code'],
            'equipment_id': row['equipment_id'],
            'payload': jsonDecode(row['payload'] as String),
          },
        )
        .toList();
  }

  /// Returns ALL inspections regardless of sync status — use this for reports/PDF.
  /// [getPendingModuleInspections] only returns isSynced=0; once pushed to server
  /// those records become isSynced=1 and disappear from that query.
  static Future<List<Map<String, dynamic>>> getAllModuleInspections({
    String? moduleCode,
  }) async {
    if (kIsWeb) return [];
    try {
      final db = await database;
      final normCode = moduleCode != null ? normalizeModuleCode(moduleCode) : null;
      final result = await db.query(
        'pending_module_sync',
        where: normCode == null ? null : 'module_code = ?',
        whereArgs: normCode == null ? null : [normCode],
        orderBy: 'rowid ASC',
      );
      return result.map((row) => {
        'event_id':    row['event_id'],
        'module_code': row['module_code'],
        'equipment_id': row['equipment_id'],
        'payload':     jsonDecode(row['payload'] as String),
        'isSynced':    row['isSynced'],
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getLatestPendingModuleInspection({
    required String equipmentId,
    String? moduleCode,
  }) async {
    final normCode = moduleCode != null ? normalizeModuleCode(moduleCode) : null;
    final items = await getAllModuleInspections(moduleCode: normCode);
    final target = equipmentId.trim().toLowerCase();

    for (final item in items.reversed) {
      final currentId = item['equipment_id']?.toString().trim().toLowerCase() ?? '';
      if (currentId == target) {
        return item;
      }
    }

    return null;
  }

  static Future<void> markModuleInspectionSynced(String eventId) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'pending_module_sync',
      {'isSynced': 1},
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
  }

  // =========================================================
  // 🔐 USER SESSION METHODS (SQLITE)
  // =========================================================
  static Future<void> saveUserSession({
    required String username,
    required String password,
    required String token,
    required String role,
  }) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert(
      'user_session',
      {
        'username': username,
        'password': password,
        'token': token,
        'role': role,
        'last_login': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, dynamic>?> getUserSession(String username) async {
    if (kIsWeb) return null;
    final db = await database;
    final result = await db.query(
      'user_session',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  static Future<Map<String, dynamic>?> getLastSession() async {
    if (kIsWeb) return null;
    final db = await database;
    final result = await db.query(
      'user_session',
      orderBy: 'last_login DESC',
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // =========================================================
  // 📋 EQUIPMENT DETAILS (SQLITE)
  // =========================================================
  static Future<List<Map<String, dynamic>>> getModuleEquipmentDetails(String moduleCode) async {
    if (kIsWeb) return [];
    final db = await database;
    final normCode = normalizeModuleCode(moduleCode);
    final result = await db.query(
      'module_records',
      where: 'module_code = ? AND record_type = ?',
      whereArgs: [normCode, 'equipment'],
    );

    return result.map((row) {
      final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      return {
        'id': row['record_id'],
        'name': data['name'] ?? data['id'] ?? 'Equipment',
        'status': data['status'] ?? 'unknown',
        'full_data': data,
      };
    }).toList();
  }

  static Future<Map<String, dynamic>?> findEquipmentModuleAndData(String id) async {
    if (kIsWeb) return null;
    final db = await database;
    final trimmed = id.trim().toLowerCase();
    
    // Normalize ID for extinguisher compatibility (remove spaces, hyphens, etc.)
    final normalized = trimmed.replaceAll("\n", "").replaceAll(" ", "").replaceAll("-", "").toUpperCase();

    // 1. Try extinguishers table first
    final result = await db.query(
      'extinguishers',
      where: 'id = ?',
      whereArgs: [normalized],
    );

    if (result.isNotEmpty) {
      return {
        'module_code': 'fire_extinguisher',
        'data': jsonDecode(result.first['data'] as String),
      };
    }

    // 2. Try module_records table (all other modules)
    // FAST PATH: Direct query by record_id using indexed primary key search
    final fastResult = await db.query(
      'module_records',
      where: "record_type = 'equipment' AND record_id = ?",
      whereArgs: [trimmed],
      limit: 1,
    );

    if (fastResult.isNotEmpty) {
      return {
        'module_code': normalizeModuleCode(fastResult.first['module_code'] as String),
        'data': jsonDecode(fastResult.first['data'] as String),
      };
    }

    // SLOW PATH (Fallback): Scan only if direct ID lookup misses
    final moduleResult = await db.query(
      'module_records',
      where: "record_type = 'equipment'",
    );

    for (final row in moduleResult) {
      final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
      final values = [
        data['sos_code'],
        data['serial_number'],
        data['id'],
        data['equipment_id'],
      ].map((v) => v?.toString().toLowerCase() ?? '');

      if (values.contains(trimmed)) {
        return {
          'module_code': normalizeModuleCode(row['module_code'] as String),
          'data': data,
        };
      }
    }

    return null;
  }

  static Future<void> updateLocalEquipmentStatusAfterInspection({
    required String moduleCode,
    required String equipmentId,
  }) async {
    if (kIsWeb) return;
    try {
      final db = await database;
      final target = equipmentId.trim().toLowerCase();
      final normCode = normalizeModuleCode(moduleCode);

      // 1. Find all matching records in module_records for this moduleCode and equipment
      final records = await db.query(
        'module_records',
        where: 'module_code = ?',
        whereArgs: [normCode],
      );

      String? oldStatus;
      Map<String, dynamic>? targetEquipmentData;
      String? oldRecordType;

      for (final row in records) {
        final recordType = row['record_type']?.toString();
        final recordId = row['record_id']?.toString().trim().toLowerCase();
        
        // Skip summary or other system record types
        if (recordType == 'summary' || recordType == 'checklist' || recordType == 'alerts' || recordType == 'single') {
          continue;
        }

        final data = jsonDecode(row['data'] as String) as Map<String, dynamic>;
        final ids = [
          data['id'],
          data['sos_code'],
          data['serial_number'],
          data['equipment_id'],
          row['record_id'],
        ].map((v) => v?.toString().trim().toLowerCase() ?? '');

        if (ids.contains(target)) {
          targetEquipmentData = data;
          if (recordType != 'equipment') {
            oldStatus = data['status']?.toString();
            oldRecordType = recordType;
          }
        }
      }

      // If we didn't find the old status from the row type, try reading from equipment data
      if (oldStatus == null && targetEquipmentData != null) {
        oldStatus = targetEquipmentData['status']?.toString();
      }

      // Map the old status value to db recordType key if needed
      String? mappedOldRecordType = oldRecordType;
      if (mappedOldRecordType == null && oldStatus != null) {
        final s = oldStatus.toLowerCase();
        if (s == 'needs-service' || s == 'needs_service') mappedOldRecordType = 'needs_service';
        else if (s == 'due-inspection' || s == 'due_inspection') mappedOldRecordType = 'due_inspection';
        else if (s == 'expired') mappedOldRecordType = 'expired';
        else if (s == 'upcoming') mappedOldRecordType = 'upcoming';
        else if (s == 'active') mappedOldRecordType = 'active';
      }

      if (targetEquipmentData != null) {
        // Update general equipment status in JSON payload
        targetEquipmentData['status'] = 'active';
        final updatedJson = jsonEncode(targetEquipmentData);
        final eqRecordId = (targetEquipmentData['id'] ?? targetEquipmentData['sos_code'] ?? equipmentId).toString();

        await db.transaction((txn) async {
          // Update the main equipment row (record_type = 'equipment')
          await txn.insert(
            'module_records',
            {
              'module_code': normCode,
              'record_type': 'equipment',
              'record_id': eqRecordId,
              'data': updatedJson,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // Delete from old status record type
          if (mappedOldRecordType != null && mappedOldRecordType != 'active') {
            await txn.delete(
              'module_records',
              where: 'module_code = ? AND record_type = ? AND record_id = ?',
              whereArgs: [normCode, mappedOldRecordType, eqRecordId],
            );
          }

          // Insert into active status record type
          await txn.insert(
            'module_records',
            {
              'module_code': normCode,
              'record_type': 'active',
              'record_id': eqRecordId,
              'data': updatedJson,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // 2. Update the cached summary map
          final summaryResult = await txn.query(
            'module_records',
            where: 'module_code = ? AND record_type = ? AND record_id = ?',
            whereArgs: [normCode, 'summary', 'single'],
            limit: 1,
          );

          if (summaryResult.isNotEmpty) {
            final summaryData = jsonDecode(summaryResult.first['data'] as String) as Map<String, dynamic>;
            
            // Helper to update summary counts safely
            void adjustCount(String keyPart, int delta) {
              summaryData.forEach((key, val) {
                final lowerKey = key.toLowerCase();
                if (lowerKey.contains(keyPart)) {
                  if (val is num) {
                    summaryData[key] = (val.toInt() + delta).clamp(0, 999999);
                  }
                }
              });
            }

            // Decrement old status count
            if (mappedOldRecordType != null) {
              if (mappedOldRecordType == 'needs_service') adjustCount('service', -1);
              else if (mappedOldRecordType == 'due_inspection') adjustCount('inspection', -1);
              else if (mappedOldRecordType == 'expired') adjustCount('expired', -1);
              else if (mappedOldRecordType == 'upcoming') adjustCount('upcoming', -1);
              else if (mappedOldRecordType == 'active') adjustCount('active', -1);
            } else {
              // Fallback: if old status was not identified, assume it was due_inspection
              adjustCount('inspection', -1);
            }

            // Increment active count
            adjustCount('active', 1);

            // Re-save the summary map
            await txn.insert(
              'module_records',
              {
                'module_code': normCode,
                'record_type': 'summary',
                'record_id': 'single',
                'data': jsonEncode(summaryData),
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        });
      }
    } catch (e) {
      print("Error updating local equipment status: $e");
    }
  }
}

