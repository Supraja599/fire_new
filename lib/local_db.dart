import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'app.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
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
      },
    );
  }

  // ================= SAVE/UPDATE LOCAL DATA =================
  static Future<void> insert(String id, Map<String, dynamic> data) async {
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

  // ================= GET SINGLE ITEM =================
  static Future<Map<String, dynamic>?> get(String id) async {
    final db = await database;

    final result = await db.query(
      'extinguishers',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return jsonDecode(result.first['data'] as String);
    }

    return null;
  }

  // ================= GET ALL IDS =================
  static Future<List<String>> getAllIds() async {
    final db = await database;

    final result = await db.query('extinguishers');

    return result.map((e) => e['id'].toString()).toList();
  }

  // ================= OFFLINE SYNC TABLE =================
  static Future<void> insertPending(String id, String data) async {
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
    final db = await database;

    return db.query(
      'pending_sync',
      where: 'isSynced = ?',
      whereArgs: [0],
    );
  }

  static Future<void> markSynced(String id) async {
    final db = await database;

    await db.update(
      'pending_sync',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}