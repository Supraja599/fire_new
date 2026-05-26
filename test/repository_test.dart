
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fire_new/local_db.dart';
import 'package:fire_new/services/equipment_repository.dart';

void main() {
  late Database db;
  late GetIt locator;

  setUpAll(() async {
    // 1. Initialize sqflite FFI for test environment
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // 2. Initialize Hive
    Hive.init('.');
    await Hive.openBox('inspectionBox');
  });

  tearDownAll(() async {
    await Hive.close();
  });

  setUp(() async {
    locator = GetIt.instance;
    if (locator.isRegistered<EquipmentRepository>()) {
      locator.unregister<EquipmentRepository>();
    }

    // 3. Open a clean in-memory database for each test
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 2,
      onOpen: (database) async {
        await database.execute('CREATE TABLE IF NOT EXISTS extinguishers (id TEXT PRIMARY KEY, data TEXT)');
        await database.execute('CREATE TABLE IF NOT EXISTS pending_sync (id TEXT PRIMARY KEY, data TEXT, isSynced INTEGER)');
        await database.execute('CREATE TABLE IF NOT EXISTS module_records (module_code TEXT, record_type TEXT, record_id TEXT, data TEXT, PRIMARY KEY (module_code, record_type, record_id))');
        await database.execute('CREATE TABLE IF NOT EXISTS pending_module_sync (event_id TEXT PRIMARY KEY, module_code TEXT, equipment_id TEXT, payload TEXT, isSynced INTEGER)');
        await database.execute('CREATE TABLE IF NOT EXISTS user_session (username TEXT PRIMARY KEY, password TEXT, token TEXT, role TEXT, last_login TEXT)');
      },
    );
    LocalDB.database = db;
  });

  tearDown(() async {
    await db.close();
  });

  group('EquipmentRepository Tests', () {
    test('Online-First lookup fetches and caches data on success', () async {
      // Mock API function that succeeds and returns search result
      final mockApiPayload = {
        'id': 'EQ101',
        'module_code': 'fire_extinguisher',
        'status': 'active',
        'serial_number': 'SN12345',
      };

      final repository = EquipmentRepository(
        apiSearchOverride: (id) async {
          if (id == 'EQ101') return mockApiPayload;
          return null;
        },
      );
      locator.registerSingleton<EquipmentRepository>(repository);

      // Verify that initially the database is empty for this ID
      final initialDbCheck = await LocalDB.get('EQ101');
      expect(initialDbCheck, isNull);

      // Call repository lookup
      final result = await locator<EquipmentRepository>().getEquipment('EQ101');

      // Assert that repository returned the mock API data
      expect(result, isNotNull);
      expect(result?['serial_number'], 'SN12345');

      // Assert that repository cached the returned payload into LocalDB (SQLite)
      final cachedDbCheck = await LocalDB.get('EQ101');
      expect(cachedDbCheck, isNotNull);
      expect(cachedDbCheck?['serial_number'], 'SN12345');
    });

    test('Offline-Fallback lookup uses database cache when network is offline', () async {
      // Seed the cache (LocalDB) directly
      final cachedPayload = {
        'id': 'EQ202',
        'module_code': 'fire_extinguisher',
        'status': 'needs-service',
        'serial_number': 'SN99999',
      };
      await LocalDB.insert('EQ202', cachedPayload);

      // Mock API function that fails (simulating network error)
      final repository = EquipmentRepository(
        apiSearchOverride: (id) async {
          throw Exception("Network connection timeout");
        },
      );
      locator.registerSingleton<EquipmentRepository>(repository);

      // Call repository lookup
      final result = await locator<EquipmentRepository>().getEquipment('EQ202');

      // Assert that repository falls back gracefully and returns cached LocalDB record
      expect(result, isNotNull);
      expect(result?['serial_number'], 'SN99999');
    });

    test('Inspection submission updates status locally and schedules sync', () async {
      bool syncTriggered = false;

      final repository = EquipmentRepository(
        apiSyncOverride: () async {
          syncTriggered = true;
        },
      );
      locator.registerSingleton<EquipmentRepository>(repository);

      // Seed equipment list so we can update its status after inspection
      final equipmentRecord = {
        'id': 'EQ303',
        'serial_number': 'SN333',
        'status': 'expired',
      };
      await LocalDB.saveModuleRecords(
        moduleCode: 'fire_extinguisher',
        recordType: 'equipment',
        items: [equipmentRecord],
      );

      // Verify status is expired initially
      final initialMatch = await LocalDB.findEquipmentModuleAndData('EQ303');
      expect(initialMatch?['data']?['status'], 'expired');

      // Submit inspection
      await locator<EquipmentRepository>().submitInspection(
        eventId: 'EV999',
        moduleCode: 'fire_extinguisher',
        equipmentId: 'EQ303',
        inspectorName: 'John Doe',
        remarks: 'All looks good',
        answers: [{'question_id': 1, 'response': 'Yes'}],
        images: [],
      );

      // 1. Verify inspection queue contains the pending record
      final pendingList = await LocalDB.getPendingModuleInspections();
      expect(pendingList.length, 1);
      expect(pendingList[0]['equipment_id'], 'EQ303');

      final payload = pendingList[0]['payload'];
      expect(payload['inspector_name'], 'John Doe');

      // 2. Verify status was updated locally to 'active' (cache update)
      final updatedMatch = await LocalDB.findEquipmentModuleAndData('EQ303');
      expect(updatedMatch?['data']?['status'], 'active');

      // 3. Verify sync function was triggered in the background
      expect(syncTriggered, isTrue);
    });
  });
}
