import 'dart:convert';
import 'package:fire_new/local_db.dart';
import 'package:fire_new/services/apiservice.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class FireBlanketsApiService {
  static const String baseUrl = "https://ehs.garrev.com/app1/v1";
  static const int moduleId = 41;
  static const String moduleCode = "fire_blanket";

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
    if (decoded is Map && decoded["items"] is List) return List<Map<String, dynamic>>.from(decoded["items"]);
    if (decoded is List) return List<Map<String, dynamic>>.from(decoded);
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
    await Future.wait([getSummary(), getEquipmentList(), getChecklist(), getAlerts()]);
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

}
