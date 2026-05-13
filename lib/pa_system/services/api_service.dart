import 'dart:convert';
import 'package:fire_new/local_db.dart';
import 'package:fire_new/services/apiservice.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class PASystemApiService {
  static const String baseUrl = "https://ehs.garrev.com/app1/v1";
  static const int moduleId = 44;
  static const String moduleCode = "pa_system";

  Map<String, String> get headers {
    final box = Hive.isBoxOpen('inspectionBox') ? Hive.box<dynamic>('inspectionBox') : null;
    final token = ApiService.token ?? box?.get('token')?.toString();
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  dynamic _decodeBody(http.Response response) {
    if (response.statusCode != 200 && response.statusCode != 201) throw Exception("API error ${response.statusCode}");
    return jsonDecode(response.body);
  }

  List<Map<String, dynamic>> _readList(dynamic decoded) {
    if (decoded is List) return List<Map<String, dynamic>>.from(decoded);
    if (decoded is Map) {
      if (decoded["items"] is List) return List<Map<String, dynamic>>.from(decoded["items"]);
      if (decoded["data"] is List) return List<Map<String, dynamic>>.from(decoded["data"]);
      if (decoded["checklists"] is List) return List<Map<String, dynamic>>.from(decoded["checklists"]);
      if (decoded["records"] is List) return List<Map<String, dynamic>>.from(decoded["records"]);
    }
    return [];
  }

  Future<Map<String, dynamic>> _getAndCacheMap(String url, String type) async {
    try {
      final res = await http.get(Uri.parse(url), headers: headers);
      final data = _decodeBody(res) as Map<String, dynamic>;
      await LocalDB.saveModuleMap(moduleCode: moduleCode, recordType: type, data: data);
      return data;
    } catch (_) { return LocalDB.getModuleMap(moduleCode: moduleCode, recordType: type); }
  }

  Future<List<Map<String, dynamic>>> _getAndCacheList(String url, String type) async {
    try {
      final res = await http.get(Uri.parse(url), headers: headers);
      final list = _readList(_decodeBody(res));
      await LocalDB.saveModuleRecords(moduleCode: moduleCode, recordType: type, items: list);
      return list;
    } catch (_) { return LocalDB.getModuleRecords(moduleCode: moduleCode, recordType: type); }
  }

  Future<Map<String, dynamic>> getSummary() => _getAndCacheMap("$baseUrl/modules/$moduleId/summary", "summary");
  Future<List<Map<String, dynamic>>> getEquipmentList() => _getAndCacheList("$baseUrl/equipment?module_id=$moduleId&limit=200", "equipment");
  Future<List<Map<String, dynamic>>> getChecklist() => _getAndCacheList("$baseUrl/modules/$moduleId/checklists", "checklist");
  Future<List<Map<String, dynamic>>> getAlerts() => _getAndCacheList("$baseUrl/alerts?module_id=$moduleId", "alerts");

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
      getPlantHealth()
    ]);
  }

  Future<Map<String, dynamic>?> getEquipmentByQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/equipment/$trimmed"),
        headers: headers,
      );

      if (response.statusCode == 404) {
        return LocalDB.findModuleEquipment(
          moduleCode: moduleCode,
          query: trimmed,
        );
      }

      final decoded = _decodeBody(response);
      if (decoded is Map<String, dynamic>) {
        final itemModuleCode = decoded["module_code"]?.toString();
        if (itemModuleCode != null && itemModuleCode != moduleCode) {
          return null; 
        }
        return decoded;
      }
      return null;
    } catch (_) {
      return LocalDB.findModuleEquipment(
        moduleCode: moduleCode,
        query: trimmed,
      );
    }
  }


  
  Future<List<Map<String, dynamic>>> getInspectionReports({required String fromDate, required String toDate}) {
    return _getAndCacheList("$baseUrl/reports/inspections?date_from=$fromDate&date_to=$toDate&module_id=$moduleId", "inspection_reports");
  }

  Future<List<Map<String, dynamic>>> getEquipmentStatusReport() {
    return _getAndCacheList("$baseUrl/reports/equipment-status?module_id=$moduleId", "equipment_status_report");
  }


  Future<List<Map<String, dynamic>>> getActive() => _getAndCacheList("$baseUrl/equipment?module_id=$moduleId&status=active", "active");
  Future<List<Map<String, dynamic>>> getNeedsService() => _getAndCacheList("$baseUrl/equipment?module_id=$moduleId&status=needs-service", "needs_service");
  Future<List<Map<String, dynamic>>> getExpired() => _getAndCacheList("$baseUrl/equipment?module_id=$moduleId&status=expired", "expired");
  Future<List<Map<String, dynamic>>> getDueInspection() => _getAndCacheList("$baseUrl/equipment?module_id=$moduleId&status=due-inspection", "due_inspection");
  Future<List<Map<String, dynamic>>> getUpcoming() => _getAndCacheList("$baseUrl/equipment?module_id=$moduleId&status=upcoming", "upcoming");
  Future<Map<String, dynamic>> getPlantHealth() => _getAndCacheMap("$baseUrl/modules/$moduleId/plant-health", "plant_health");
  


}