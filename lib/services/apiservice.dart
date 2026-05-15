import 'dart:convert';
import 'package:http/http.dart' as http;
import '../local_db.dart';

class ApiService {
  static const String baseUrl = "https://ehs.garrev.com/app1/v1";

  // 🔐 Store token (set after login)
  static String? token;

  // ================= COMMON HEADERS =================
  static Map<String, String> get headers {
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // =========================================================
  // 🔐 LOGIN API
  // =========================================================
  static Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final url = Uri.parse("$baseUrl/auth/login");
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          "username": username.trim(),
          "password": password.trim(),
        }),
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          token = decoded["token"];
          return decoded;
        }
      }
      return null;
    } catch (e) {
      print("LOGIN ERROR: $e");
      return null;
    }
  }

  // =========================================================
  // 📋 FIRE EXTINGUISHER CHECKLIST API
  // =========================================================
  static const String checklistUrl = "$baseUrl/modules/30/checklists";

  static Future<List<Map<String, dynamic>>> getFireChecklist() async {
    try {
      final res = await http.get(Uri.parse(checklistUrl), headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final decoded = jsonDecode(res.body);
      if (decoded is List) return List<Map<String, dynamic>>.from(decoded);
      if (decoded is Map && decoded["items"] is List) return List<Map<String, dynamic>>.from(decoded["items"]);
      if (decoded is Map && decoded["data"] is List) return List<Map<String, dynamic>>.from(decoded["data"]);
      return [];
    } catch (e) {
      print("CHECKLIST GET ERROR: $e");
      return [];
    }
  }

  static Future<bool> updateFireChecklist(List<Map<String, dynamic>> data) async {
    try {
      final res = await http.post(Uri.parse(checklistUrl), headers: headers, body: jsonEncode(data)).timeout(const Duration(seconds: 10));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print("CHECKLIST POST ERROR: $e");
      return false;
    }
  }

  // ================= NORMALIZE =================
  static String normalize(String value) {
    return value.trim().replaceAll("\n", "").replaceAll(" ", "").replaceAll("-", "").toUpperCase();
  }

  // =========================================================
  // 🔍 SEARCH
  // =========================================================
  static Future<Map<String, dynamic>?> searchAny(String input) async {
    final id = normalize(input);
    try {
      // 1. Try generic equipment endpoint first
      final url = "$baseUrl/equipment/$id";
      final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 5));
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          // Some APIs wrap in "item" or "data"
          final data = decoded.containsKey("item") ? decoded["item"] : (decoded.containsKey("data") ? decoded["data"] : decoded);
          if (data is Map<String, dynamic>) {
            return data;
          }
        }
      }

      // 2. Fallback to legacy extinguishers endpoint
      final extUrl = "$baseUrl/extinguishers/$id";
      final extRes = await http.get(Uri.parse(extUrl), headers: headers).timeout(const Duration(seconds: 5));
      if (extRes.statusCode == 200) {
        final decoded = jsonDecode(extRes.body);
        if (decoded is Map && decoded.containsKey("item")) {
          return Map<String, dynamic>.from(decoded["item"]);
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }

      // 3. Final fallback to local DB
      return await LocalDB.get(id);
    } catch (e) {
      print("GLOBAL SEARCH ERROR: $e");
      return await LocalDB.get(id);
    }
  }

  // =========================================================
  // 📊 COMMON GET LIST HANDLER
  // =========================================================
  static Future<List<Map<String, dynamic>>> _getList(String url) async {
    // Determine a unique cache key based on the endpoint
    String cacheKey = url.split('/').last; 
    if (cacheKey.contains('?')) cacheKey = cacheKey.split('?').first;
    
    try {
      final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
         return await LocalDB.getModuleRecords(moduleCode: "fire_extinguisher", recordType: cacheKey);
      }
      final decoded = jsonDecode(res.body);
      List<Map<String, dynamic>> items = [];
      if (decoded is Map && decoded["items"] is List) items = List<Map<String, dynamic>>.from(decoded["items"]);
      else if (decoded is Map && decoded["alerts"] is List) items = List<Map<String, dynamic>>.from(decoded["alerts"]);
      else if (decoded is List) items = List<Map<String, dynamic>>.from(decoded);
      
      if (items.isNotEmpty) {
        await LocalDB.saveModuleRecords(moduleCode: "fire_extinguisher", recordType: cacheKey, items: items);
      }
      return items;
    } catch (e) {
      print("API ERROR ($cacheKey Offline Fallback): $e");
      return await LocalDB.getModuleRecords(moduleCode: "fire_extinguisher", recordType: cacheKey);
    }
  }

  // ================= APIs =================
  static Future<List<Map<String, dynamic>>> getAlerts() => _getList("$baseUrl/alerts");

  static int calculateHealth(Map<String, dynamic> s) {
    if (s.isEmpty) return 100;
    
    // 1. Direct fields
    int total = s["total"] ?? s["total_units"] ?? s["total_loops"] ?? s["total_extinguishers"] ?? 0;
    int expired = s["expired"] ?? s["expired_units"] ?? s["expired_loops"] ?? s["expired_extinguishers"] ?? 0;
    int active = s["active"] ?? s["active_units"] ?? s["active_loops"] ?? s["active_extinguishers"] ?? 0;
    int service = s["needs_service"] ?? s["needs_service_units"] ?? s["needs_service_extinguishers"] ?? 0;
    
    // 2. Dynamic pattern matching for all 24 modules
    s.forEach((key, value) {
      if (value is int) {
        final lowerKey = key.toLowerCase();
        if (lowerKey.startsWith("total_") && total == 0) total = value;
        if (lowerKey.startsWith("expired_") && expired == 0) expired = value;
        if (lowerKey.startsWith("active_") && active == 0) active = value;
        if (lowerKey.contains("needs_service") && service == 0) service = value;
      }
    });
    
    // 3. Component sum fallback
    if (total == 0) total = active + service + expired;
    
    // 4. Final Calculation: (Total - Expired) / Total
    if (total > 0) {
      return (((total - expired) / total) * 100).toInt();
    }
    
    return 100; // Default to 100 if no data
  }

  static Future<Map<String, dynamic>> getGlobalDashboard() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/dashboard"), headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print("DASHBOARD API ERROR: $e");
      return {};
    }
  }

  static Future<Map<String, dynamic>> getSummary() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/modules/30/summary"), headers: headers).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        await LocalDB.saveModuleMap(moduleCode: "fire_extinguisher", recordType: "summary", data: data);
        return data;
      }
      return await LocalDB.getModuleMap(moduleCode: "fire_extinguisher", recordType: "summary");
    } catch (e) {
      print("SUMMARY ERROR: $e");
      return await LocalDB.getModuleMap(moduleCode: "fire_extinguisher", recordType: "summary");
    }
  }

  static Future<List<Map<String, dynamic>>> getAll() => _getList("$baseUrl/extinguishers");
  static Future<List<Map<String, dynamic>>> getActive() => _getList("$baseUrl/status/active");
  static Future<List<Map<String, dynamic>>> getNeedsService() => _getList("$baseUrl/status/needs-service");
  static Future<List<Map<String, dynamic>>> getExpired() => _getList("$baseUrl/status/expired");
  static Future<List<Map<String, dynamic>>> getDueInspection() => _getList("$baseUrl/status/due-inspection");
  static Future<List<Map<String, dynamic>>> getUpcoming() => _getList("$baseUrl/status/upcoming");
  static Future<List<Map<String, dynamic>>> getEquipmentStatus() => _getList("$baseUrl/reports/equipment-status");

  static Future<List<Map<String, dynamic>>> getInspections(String start, String end) =>
      _getList("$baseUrl/reports/inspections?start_date=$start&end_date=$end");

  static Future<void> syncModuleData() async {
    await Future.wait([
      getSummary(),
      getFireChecklist(),
      getAlerts(),
      getActive(),
      getNeedsService(),
      getExpired(),
      getDueInspection(),
      getUpcoming(),
      getEquipmentStatus(),
      syncAllExtinguishersToLocal()
    ]);
  }

  static Future<void> syncAllExtinguishersToLocal() async {
    try {
      final list = await getAll();
      if (list.isNotEmpty) {
        await LocalDB.saveAllExtinguishers(list);
      }
    } catch (e) {
      print("❌ SYNC ERROR: $e");
    }
  }

  static Future<bool> submitEquipmentInspection({required String equipmentId, required Map<String, dynamic> payload}) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/equipment/$equipmentId/inspections"),
        headers: headers,
        body: jsonEncode(payload),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) { return false; }
  }

  static Future<void> syncPendingModuleInspections() async {
    final pendingItems = await LocalDB.getPendingModuleInspections();
    for (final item in pendingItems) {
      final equipmentId = item['equipment_id']?.toString();
      final eventId = item['event_id']?.toString();
      if (equipmentId == null || equipmentId.isEmpty || eventId == null) continue;
      final success = await submitEquipmentInspection(
        equipmentId: equipmentId,
        payload: Map<String, dynamic>.from(item['payload'] ?? {}),
      );
      if (success) await LocalDB.markModuleInspectionSynced(eventId);
    }
  }

  static Future<bool> insertVersion(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/status/insert-version"),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) { return false; }
  }

  static Future<bool> sendToServer(String data) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/equipment"),
        headers: headers,
        body: data,
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) { return false; }
  }
}
