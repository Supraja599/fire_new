import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDB {
  static Database? _db;

  static Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError("sqflite (LocalDB) is not supported on Web. Please run on Android or Windows.");
    }
    if (_db != null) return _db!;
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
    
    // Search in ALL records (active, needs_service, equipment, etc.)
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

    batch.delete(
      'module_records',
      where: 'module_code = ? AND record_type = ?',
      whereArgs: [moduleCode, recordType],
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
          'module_code': moduleCode,
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
    final recordId = (item['id'] ??
            item['sos_code'] ??
            item['serial_number'] ??
            'unknown')
        .toString();

    await db.insert(
      'module_records',
      {
        'module_code': moduleCode,
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
      final result = await db.query(
        'module_records',
        where: 'module_code = ? AND record_type = ?',
        whereArgs: [moduleCode, recordType],
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
    await db.insert(
      'module_records',
      {
        'module_code': moduleCode,
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
      final result = await db.query(
        'module_records',
        where: 'module_code = ? AND record_type = ? AND record_id = ?',
        whereArgs: [moduleCode, recordType, 'single'],
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
    final items = await getModuleRecords(
      moduleCode: moduleCode,
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
    await db.insert(
      'pending_module_sync',
      {
        'event_id': eventId,
        'module_code': moduleCode,
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
    final result = await db.query(
      'pending_module_sync',
      where: moduleCode == null ? 'isSynced = ?' : 'isSynced = ? AND module_code = ?',
      whereArgs: moduleCode == null ? [0] : [0, moduleCode],
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

  static Future<Map<String, dynamic>?> getLatestPendingModuleInspection({
    required String equipmentId,
    String? moduleCode,
  }) async {
    final items = await getPendingModuleInspections(moduleCode: moduleCode);
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
    final result = await db.query(
      'module_records',
      where: 'module_code = ? AND record_type = ?',
      whereArgs: [moduleCode, 'equipment'],
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
}
