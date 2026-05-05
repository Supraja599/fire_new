import 'dart:convert';

import 'package:fire_new/local_db.dart';
import 'package:fire_new/services/apiservice.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class SprinklerApiService {
  static const String baseUrl = "https://ehs.garrev.com/app1/v1";
  static const int moduleId = 31;
  static const String moduleCode = "sprinkler";

  Map<String, String> get headers {
    final box = Hive.isBoxOpen('inspectionBox')
        ? Hive.box<dynamic>('inspectionBox')
        : null;
    final token = ApiService.token ?? box?.get('token')?.toString();

    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null && token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }

  dynamic _decodeBody(http.Response response) {
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("API error ${response.statusCode}: ${response.body}");
    }
    return jsonDecode(response.body);
  }

  List<Map<String, dynamic>> _readList(dynamic decoded) {
    if (decoded is Map && decoded["items"] is List) {
      return List<Map<String, dynamic>>.from(decoded["items"]);
    }
    if (decoded is Map && decoded["data"] is List) {
      return List<Map<String, dynamic>>.from(decoded["data"]);
    }
    if (decoded is List) {
      return List<Map<String, dynamic>>.from(decoded);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _getAndCacheList(
    String url,
    String recordType,
  ) async {
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      final items = _readList(_decodeBody(response));
      await LocalDB.saveModuleRecords(
        moduleCode: moduleCode,
        recordType: recordType,
        items: items,
      );
      return items;
    } catch (_) {
      return LocalDB.getModuleRecords(
        moduleCode: moduleCode,
        recordType: recordType,
      );
    }
  }

  Future<Map<String, dynamic>> _getAndCacheMap(
    String url,
    String recordType,
  ) async {
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      final decoded = _decodeBody(response);
      final data = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};
      await LocalDB.saveModuleMap(
        moduleCode: moduleCode,
        recordType: recordType,
        data: data,
      );
      return data;
    } catch (_) {
      return LocalDB.getModuleMap(
        moduleCode: moduleCode,
        recordType: recordType,
      );
    }
  }

  Future<Map<String, dynamic>> getSummary() {
    return _getAndCacheMap("$baseUrl/modules/$moduleId/summary", "summary");
  }

  Future<List<Map<String, dynamic>>> getEquipmentList({int limit = 200}) {
    return _getAndCacheList(
      "$baseUrl/equipment?module_code=$moduleCode&limit=$limit",
      "equipment",
    );
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
        // ✅ Ensure the equipment belongs to THIS module
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

  Future<List<Map<String, dynamic>>> getChecklist() {
    return _getAndCacheList(
      "$baseUrl/modules/$moduleId/checklists",
      "checklist",
    );
  }

  Future<List<Map<String, dynamic>>> getAlerts() {
    return _getAndCacheList("$baseUrl/alerts?module_id=$moduleId", "alerts");
  }

  Future<Map<String, dynamic>> getAlertSummary() {
    return _getAndCacheMap(
      "$baseUrl/alerts/summary?module_id=$moduleId",
      "alert_summary",
    );
  }

  Future<List<Map<String, dynamic>>> getInspectionReports({
    required String fromDate,
    required String toDate,
  }) {
    return _getAndCacheList(
      "$baseUrl/reports/inspections?date_from=$fromDate&date_to=$toDate&module_id=$moduleId",
      "inspection_reports",
    );
  }

  Future<List<Map<String, dynamic>>> getEquipmentStatusReport() {
    return _getAndCacheList(
      "$baseUrl/reports/equipment-status?module_id=$moduleId",
      "equipment_status_report",
    );
  }

  Future<void> syncModuleData() async {
    await Future.wait([
      getSummary(),
      getEquipmentList(),
      getChecklist(),
      getAlerts(),
      getAlertSummary(),
    ]);
  }
}
