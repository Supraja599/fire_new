import 'dart:convert';
import 'dart:io';
import 'package:fire_new/local_db.dart';
import 'package:fire_new/services/apiservice.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class ModuleApiService {
  static const String _base = "https://ehs.garrev.com/app1/v1";

  final String moduleCode;
  final int moduleId;

  const ModuleApiService({required this.moduleCode, required this.moduleId});

  // ── Pre-built instances for every module ──────────────────────────────────
  static final extinguisher   = ModuleApiService(moduleCode: 'fire_extinguisher',  moduleId: 30);
  static final hoseReel       = ModuleApiService(moduleCode: 'hose_reel',          moduleId: 33);
  static final sprinkler      = ModuleApiService(moduleCode: 'sprinkler',          moduleId: 31);
  static final hydrant        = ModuleApiService(moduleCode: 'hydrant',            moduleId: 34);
  static final alarmPanel     = ModuleApiService(moduleCode: 'fire_alarm',         moduleId: 35);
  static final smokeDetector  = ModuleApiService(moduleCode: 'smoke_detector',     moduleId: 36);
  static final fireTrolley    = ModuleApiService(moduleCode: 'fire_trolley',       moduleId: 55);
  static final emergencyExit  = ModuleApiService(moduleCode: 'exit_sign',          moduleId: 39);
  static final ambulance      = ModuleApiService(moduleCode: 'ambulance',          moduleId: 58);
  static final emergencyLight = ModuleApiService(moduleCode: 'emergency_light',    moduleId: 38);
  static final paSystem       = ModuleApiService(moduleCode: 'pa_system',          moduleId: 44);
  static final windSock       = ModuleApiService(moduleCode: 'wind_sock',          moduleId: 56);
  static final scbaUnit       = ModuleApiService(moduleCode: 'scba_unit',          moduleId: 57);
  static final firstAid       = ModuleApiService(moduleCode: 'first_aid_kit',      moduleId: 45);
  static final safetyShower   = ModuleApiService(moduleCode: 'safety_shower',      moduleId: 47);
  static final eyeWash        = ModuleApiService(moduleCode: 'eyewash_station',    moduleId: 46);
  static final spillKit       = ModuleApiService(moduleCode: 'spill_kit',          moduleId: 48);
  static final ppeCabinet     = ModuleApiService(moduleCode: 'ppe_station',        moduleId: 49);
  static final co2System      = ModuleApiService(moduleCode: 'suppression_system', moduleId: 42);
  static final signage        = ModuleApiService(moduleCode: 'signage',            moduleId: 62);
  static final emergencyComm  = ModuleApiService(moduleCode: 'emergency_comm',     moduleId: 61);
  static final fireBlanket    = ModuleApiService(moduleCode: 'fire_blanket',       moduleId: 41);
  static final musterPoint    = ModuleApiService(moduleCode: 'muster_point',       moduleId: 59);
  static final heatDetector   = ModuleApiService(moduleCode: 'heat_detector',      moduleId: 37);
  static final coDetector     = ModuleApiService(moduleCode: 'co_detector',        moduleId: 40);
  static final fireDoor       = ModuleApiService(moduleCode: 'fire_door',          moduleId: 43);
  static final sandBucket     = ModuleApiService(moduleCode: 'sand_bucket',        moduleId: 63);


  // ── Headers ───────────────────────────────────────────────────────────────
  Map<String, String> get headers {
    final box = Hive.isBoxOpen('inspectionBox') ? Hive.box<dynamic>('inspectionBox') : null;
    final token = ApiService.token ?? box?.get('token')?.toString();
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  // ── Internal helpers ──────────────────────────────────────────────────────
  dynamic _decodeBody(http.Response res) {
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("API ${res.statusCode}: ${res.body}");
    }
    return jsonDecode(res.body);
  }

  List<Map<String, dynamic>> _readList(dynamic d) {
    if (d is Map && d["items"] is List) return List<Map<String, dynamic>>.from(d["items"]);
    if (d is Map && d["data"]  is List) return List<Map<String, dynamic>>.from(d["data"]);
    if (d is Map && d["checklists"] is List) return List<Map<String, dynamic>>.from(d["checklists"]);
    if (d is List)                      return List<Map<String, dynamic>>.from(d);
    return [];
  }

  Future<List<Map<String, dynamic>>> _getList(String url, String type) async {
    try {
      final res   = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));
      final items = _readList(_decodeBody(res));
      await LocalDB.saveModuleRecords(moduleCode: moduleCode, recordType: type, items: items);
      return items;
    } catch (_) {
      return LocalDB.getModuleRecords(moduleCode: moduleCode, recordType: type);
    }
  }

  Future<Map<String, dynamic>> _getMap(String url, String type) async {
    try {
      final res     = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));
      final decoded = _decodeBody(res);
      final data    = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      await LocalDB.saveModuleMap(moduleCode: moduleCode, recordType: type, data: data);
      return data;
    } catch (_) {
      return LocalDB.getModuleMap(moduleCode: moduleCode, recordType: type);
    }
  }

  // ── Read APIs ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getSummary() =>
      _getMap("$_base/modules/$moduleId/summary", "summary");

  Future<Map<String, dynamic>> getPlantHealth() =>
      _getMap("$_base/modules/$moduleId/plant-health", "plant_health");

  Future<List<Map<String, dynamic>>> getEquipmentList({int limit = 2000}) =>
      _getList("$_base/equipment?module_code=$moduleCode&limit=$limit", "equipment");

  Future<Map<String, dynamic>?> getEquipmentByQuery(String query) async {
    final q = query.trim();
    if (q.isEmpty) return null;
    try {
      final res = await http.get(Uri.parse("$_base/equipment/$q"), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 404) {
        return LocalDB.findModuleEquipment(moduleCode: moduleCode, query: q);
      }
      final decoded = _decodeBody(res);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey("module_code") && decoded["module_code"] != null) {
          decoded["module_code"] = LocalDB.normalizeModuleCode(decoded["module_code"].toString());
        }
        final mc = decoded["module_code"]?.toString();
        if (mc != null && mc != LocalDB.normalizeModuleCode(moduleCode)) return null;
        return decoded;
      }
      return null;
    } catch (_) {
      return LocalDB.findModuleEquipment(moduleCode: moduleCode, query: q);
    }
  }

  Future<List<Map<String, dynamic>>> getChecklist() =>
      _getList("$_base/checklists/$moduleCode", "checklist");

  Future<List<Map<String, dynamic>>> getAlerts() =>
      _getList("$_base/alerts?module_id=$moduleId", "alerts");

  Future<Map<String, dynamic>> getAlertSummary() =>
      _getMap("$_base/alerts/summary?module_id=$moduleId", "alert_summary");

  Future<List<Map<String, dynamic>>> getInspectionReports({
    required String fromDate,
    required String toDate,
  }) =>
      _getList(
        "$_base/reports/inspections?date_from=$fromDate&date_to=$toDate&module_id=$moduleId",
        "inspection_reports",
      );

  Future<List<Map<String, dynamic>>> getEquipmentStatusReport() =>
      _getList("$_base/reports/equipment-status?module_id=$moduleId", "equipment_status_report");

  Future<List<Map<String, dynamic>>> getActive() =>
      _getList("$_base/equipment?module_id=$moduleId&status=active", "active");

  Future<List<Map<String, dynamic>>> getNeedsService() =>
      _getList("$_base/equipment?module_id=$moduleId&status=needs-service", "needs_service");

  Future<List<Map<String, dynamic>>> getExpired() =>
      _getList("$_base/equipment?module_id=$moduleId&status=expired", "expired");

  Future<List<Map<String, dynamic>>> getDueInspection() =>
      _getList("$_base/equipment?module_id=$moduleId&status=due-inspection", "due_inspection");

  Future<List<Map<String, dynamic>>> getUpcoming() =>
      _getList("$_base/equipment?module_id=$moduleId&status=upcoming", "upcoming");

  // ── Write APIs ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> postChecklistItem({
    required int itemOrder,
    required String category,
    required String itemText,
    required String answerType,
    bool isCritical = false,
    bool isDefect = false,
    String hints = '',
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$_base/admin/checklists/$moduleCode/items"),
        headers: headers,
        body: jsonEncode({
          "item_order":  itemOrder,
          "category":    category,
          "item_text":   itemText,
          "answer_type": answerType,
          "is_critical": isCritical,
          "is_defect":   isDefect,
          "hints":       hints,
        }),
      ).timeout(const Duration(seconds: 10));
      final decoded = _decodeBody(res);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (e) {
      print("POST CHECKLIST ITEM ERROR ($moduleCode): $e");
      return null;
    }
  }

  // ── Pre-check (photo slot requirements with sample images) ───────────────
  Future<Map<String, dynamic>> getPreCheck() =>
      _getMap("$_base/modules/$moduleCode/pre-check", "pre_check");

  /// POSTs a pre-check inspection with 4 photos as multipart/form-data.
  /// Returns true on 200/201, false on any error (non-blocking — caller should fire-and-forget).
  static Future<bool> submitPreCheck({
    required String equipmentId,
    required String equipmentType,
    required String inspectorName,
    required List<String> imagePaths,
  }) async {
    const base = "https://ehs.garrev.com/app1/v1";
    try {
      final box = Hive.isBoxOpen('inspectionBox') ? Hive.box<dynamic>('inspectionBox') : null;
      final token = ApiService.token ?? box?.get('token')?.toString();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse("$base/inspections/pre-check"),
      );
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.fields['equipment_id'] = equipmentId;
      request.fields['equipment_type'] = equipmentType;
      request.fields['inspector_name'] = inspectorName;

      for (int i = 0; i < imagePaths.length; i++) {
        final file = File(imagePaths[i]);
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath(
            'image_${i + 1}',
            imagePaths[i],
          ));
        }
      }

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      return streamed.statusCode == 200 || streamed.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// Fetches the ordered photo requirements (slot, label, desc, sample_image_url)
  /// for a given module code. Returns empty list on any error.
  static Future<List<Map<String, dynamic>>> fetchPreCheckRequirements(String moduleCode) async {
    const base = "https://ehs.garrev.com/app1/v1";
    try {
      final box = Hive.isBoxOpen('inspectionBox') ? Hive.box<dynamic>('inspectionBox') : null;
      final token = ApiService.token ?? box?.get('token')?.toString();
      final hdrs = <String, String>{
        "Content-Type": "application/json",
        "Accept": "application/json",
        if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
      };
      final res = await http.get(
        Uri.parse("$base/modules/$moduleCode/pre-check"),
        headers: hdrs,
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data["requirements"] is List) {
          return List<Map<String, dynamic>>.from(data["requirements"]);
        }
      }
    } catch (_) {}
    return [];
  }

  // ── Sync all ──────────────────────────────────────────────────────────────
  Future<void> syncModuleData() async {
    await Future.wait([
      getSummary(),
      getEquipmentList(),
      getChecklist(),
      getAlerts(),
      getActive(),
      getNeedsService(),
      getExpired(),
      getDueInspection(),
      getUpcoming(),
      getPlantHealth(),
    ]);
  }
}
