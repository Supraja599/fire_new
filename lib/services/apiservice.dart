import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as origin_http;
import 'package:hive/hive.dart';
import '../local_db.dart';
import 'error_handler.dart';
import '../main.dart';

class ApiService {
  static const String baseUrl = "https://ehs.garrev.com/app1/v1";

  // 🔐 Store token (set after login)
  static String? token;

  // 🚪 Force logout and redirect to login page when token is invalid
  static void handleUnauthorized() async {
    token = null;
    try {
      if (Hive.isBoxOpen('inspectionBox')) {
        final box = Hive.box('inspectionBox');
        await box.delete('token');
      }
    } catch (_) {}

    final context = AppExceptionHandler.navigatorKey.currentContext;
    if (context != null) {
      // Show snackbar notifying session expiration
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Session expired. Please log in again."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      
      // Redirect to login page
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  // ================= COMMON HEADERS =================
  static Map<String, String> get headers {
    final box = Hive.isBoxOpen('inspectionBox') ? Hive.box<dynamic>('inspectionBox') : null;
    final activeToken = token ?? box?.get('token')?.toString();
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (activeToken != null && activeToken.isNotEmpty) "Authorization": "Bearer $activeToken",
    };
  }

  // =========================================================
  // 🔐 LOGIN API
  // =========================================================
  static Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final url = Uri.parse("$baseUrl/auth/login");
      final res = await origin_http.post(
        url,
        headers: headers,
        body: jsonEncode({
          "username": username.trim(),
          "password": password.trim(),
        }),
      ).timeout(const Duration(seconds: 10)); // Increased to 10s for reliability
 
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          token = decoded["token"];
          return decoded;
        }
      } else if (res.statusCode == 400 || res.statusCode == 401 || res.statusCode == 403) {
        print("LOGIN FAILED: ${res.statusCode} - ${res.body}");
        return null;
      } else {
        print("LOGIN SERVER ERROR: ${res.statusCode} - ${res.body}");
        throw origin_http.ClientException("Server returned status code ${res.statusCode}");
      }
      return null;
    } catch (e) {
      print("LOGIN NETWORK ERROR: $e");
      rethrow;
    }
  }

  // =========================================================
  // 📋 FIRE EXTINGUISHER CHECKLIST API
  // =========================================================
  static const String checklistUrl = "$baseUrl/checklists/fire_extinguisher";

  static Future<List<Map<String, dynamic>>> getFireChecklist() async {
    try {
      final res = await http.get(Uri.parse(checklistUrl), headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final decoded = jsonDecode(res.body);
      if (decoded is List) return List<Map<String, dynamic>>.from(decoded);
      if (decoded is Map && decoded["items"] is List) return List<Map<String, dynamic>>.from(decoded["items"]);
      if (decoded is Map && decoded["data"] is List) return List<Map<String, dynamic>>.from(decoded["data"]);
      if (decoded is Map && decoded["checklists"] is List) return List<Map<String, dynamic>>.from(decoded["checklists"]);
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
            if (data.containsKey("module_code") && data["module_code"] != null) {
              data["module_code"] = LocalDB.normalizeModuleCode(data["module_code"].toString());
            }
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
          final itemData = Map<String, dynamic>.from(decoded["item"]);
          if (itemData.containsKey("module_code") && itemData["module_code"] != null) {
            itemData["module_code"] = LocalDB.normalizeModuleCode(itemData["module_code"].toString());
          }
          return itemData;
        }
        if (decoded is Map) {
          final itemData = Map<String, dynamic>.from(decoded);
          if (itemData.containsKey("module_code") && itemData["module_code"] != null) {
            itemData["module_code"] = LocalDB.normalizeModuleCode(itemData["module_code"].toString());
          }
          return itemData;
        }
      }

      // 3. Final fallback to local DB
      return await LocalDB.get(id);
    } catch (e) {
      print("GLOBAL SEARCH ERROR: $e");
      return await LocalDB.get(id);
    }
  }

  static Future<Map<String, dynamic>?> searchAnyOnline(String input) async {
    final id = normalize(input);
    // 1. Try generic equipment endpoint first
    final url = "$baseUrl/equipment/$id";
    final res = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 5));
    
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        final data = decoded.containsKey("item") ? decoded["item"] : (decoded.containsKey("data") ? decoded["data"] : decoded);
        if (data is Map<String, dynamic>) {
          if (data.containsKey("module_code") && data["module_code"] != null) {
            data["module_code"] = LocalDB.normalizeModuleCode(data["module_code"].toString());
          }
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
        final itemData = Map<String, dynamic>.from(decoded["item"]);
        if (itemData.containsKey("module_code") && itemData["module_code"] != null) {
          itemData["module_code"] = LocalDB.normalizeModuleCode(itemData["module_code"].toString());
        }
        return itemData;
      }
      if (decoded is Map) {
        final itemData = Map<String, dynamic>.from(decoded);
        if (itemData.containsKey("module_code") && itemData["module_code"] != null) {
          itemData["module_code"] = LocalDB.normalizeModuleCode(itemData["module_code"].toString());
        }
        return itemData;
      }
    }

    return null;
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

  /// Reads health score from API: prefers readiness_score, then health_score, then calculated.
  static int getHealthScore(Map<String, dynamic> s) {
    final rs = s["readiness_score"] ?? s["health_score"] ?? s["health"] ?? s["score"];
    if (rs != null) return (rs as num).toInt();
    return calculateHealth(s);
  }

  /// Maps status string for the icons page based strictly on client-side health thresholds.
  static String getHealthStatus(Map<String, dynamic> s, int health) {
    if (health >= 90) return "green";
    if (health >= 80) return "amber";
    return "red";
  }

  static int calculateHealth(Map<String, dynamic> s) {
    if (s.isEmpty) return 100;
    
    int upcoming = (s["upcoming"] ?? s["upcoming_units"] ?? 0) as int;
    int active = (s["active_units"] ?? s["active"] ?? s["active_loops"] ?? 0) as int;
    int service = (s["needs_service"] ?? s["needs_service_units"] ?? 0) as int;
    int inspection = (s["due_inspection"] ?? s["due_inspection_units"] ?? s["due_inspection_loops"] ?? 0) as int;
    int expired = (s["expired"] ?? s["expired_units"] ?? s["expired_loops"] ?? 0) as int;
    int total = (s["total"] ?? s["total_units"] ?? s["total_loops"] ?? s["total_extinguishers"] ?? 0) as int;

    s.forEach((key, val) {
      if (val is num) {
        final intValue = val.toInt();
        final lowerKey = key.toLowerCase();
        if (lowerKey.contains("active") && lowerKey != "active") active = intValue;
        if (lowerKey.contains("total") && lowerKey != "total") total = intValue;
        if (lowerKey.contains("expired") && lowerKey != "expired") expired = intValue;
        if (lowerKey.contains("service") && lowerKey != "needs_service") service = intValue;
        if (lowerKey.contains("inspection") && lowerKey != "due_inspection") inspection = intValue;
        if (lowerKey.contains("upcoming") && lowerKey != "upcoming") upcoming = intValue;
      }
    });

    active = active + upcoming;
    total = active + service + inspection + expired;

    if (total > 0) {
      return ((active / total) * 100).toInt();
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

  /// Fetches the latest inspection record from the server.
  /// Server is always the authoritative source — works 10 days, 1 year, 10 years later.
  static Future<Map<String, dynamic>?> getLatestInspectionForEquipment(String sosCode) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/equipment/$sosCode/inspections/latest"),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final items = data["items"] as List? ?? [];
      return {
        "inspector_name":  data["inspector_name"] ?? data["inspected_by"] ?? "N/A",
        "remarks":         data["remarks"] ?? "",
        "inspection_date": data["inspection_date"] ?? data["inspected_at"]
                            ?? data["created_at"] ?? data["date"],
        "answers": items.map((it) => {
          "checklist_item_id": it["checklist_item_id"],
          "item_text":         it["question"] ?? it["item_text"] ?? "Item",
          "answer":            it["answer"]?.toString() ?? "na",
          "remarks":           it["remarks"] ?? "",
        }).toList(),
        "images":          data["images"] ?? data["photos"] ?? [],
      };
    } catch (_) {
      return null;
    }
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
      final decoded = jsonDecode(data);
      final id = (decoded['id'] ?? decoded['sos_code'] ?? decoded['equipment_id'] ?? '').toString().trim();
      final url = id.isNotEmpty ? "$baseUrl/equipment/$id" : "$baseUrl/equipment";
      
      final res = await http.post(
        Uri.parse(url),
        headers: headers,
        body: data,
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) { return false; }
  }

  // =========================================================
  // 🔄 EQUIPMENT UPDATES WORKFLOW APIs
  // =========================================================
  
  static Future<Map<String, dynamic>?> createEquipmentUpdateRequest(
      String equipmentId, Map<String, dynamic> proposedChanges) async {
    try {
      final url = Uri.parse("$baseUrl/equipment/$equipmentId/updates");
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          "proposed_changes": proposedChanges,
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      print("CREATE UPDATE FAILED: ${res.statusCode} - ${res.body}");
      return null;
    } catch (e) {
      print("CREATE UPDATE ERROR: $e");
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getUpdates() async {
    try {
      final url = Uri.parse("$baseUrl/updates");
      final res = await http.get(url, headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        } else if (decoded is Map && decoded["data"] is List) {
          return List<Map<String, dynamic>>.from(decoded["data"]);
        } else if (decoded is Map && decoded["items"] is List) {
          return List<Map<String, dynamic>>.from(decoded["items"]);
        }
      }
      return [];
    } catch (e) {
      print("GET UPDATES ERROR: $e");
      return [];
    }
  }

  static Future<bool> supervisorApproveUpdate(String updateId, String remarks) async {
    try {
      final url = Uri.parse("$baseUrl/updates/$updateId/supervisor-approve");
      final res = await http.patch(
        url,
        headers: headers,
        body: jsonEncode({"review_remarks": remarks}),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      print("SUPERVISOR APPROVE ERROR: $e");
      return false;
    }
  }

  static Future<bool> supervisorRejectUpdate(String updateId, String remarks) async {
    try {
      final url = Uri.parse("$baseUrl/updates/$updateId/supervisor-reject");
      final res = await http.patch(
        url,
        headers: headers,
        body: jsonEncode({"review_remarks": remarks}),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      print("SUPERVISOR REJECT ERROR: $e");
      return false;
    }
  }

  static Future<bool> adminApproveUpdate(String updateId, String remarks) async {
    try {
      final url = Uri.parse("$baseUrl/updates/$updateId/admin-approve");
      final res = await http.patch(
        url,
        headers: headers,
        body: jsonEncode({"review_remarks": remarks}),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      print("ADMIN APPROVE ERROR: $e");
      return false;
    }
  }

  static Future<bool> adminRejectUpdate(String updateId, String remarks) async {
    try {
      final url = Uri.parse("$baseUrl/updates/$updateId/admin-reject");
      final res = await http.patch(
        url,
        headers: headers,
        body: jsonEncode({"review_remarks": remarks}),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      print("ADMIN REJECT ERROR: $e");
      return false;
    }
  }

  // =========================================================
  // 🔔 NOTIFICATIONS APIs
  // =========================================================

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final url = Uri.parse("$baseUrl/notifications");
      final res = await http.get(url, headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        } else if (decoded is Map && decoded["data"] is List) {
          return List<Map<String, dynamic>>.from(decoded["data"]);
        } else if (decoded is Map && decoded["items"] is List) {
          return List<Map<String, dynamic>>.from(decoded["items"]);
        }
      }
      return [];
    } catch (e) {
      print("GET NOTIFICATIONS ERROR: $e");
      return [];
    }
  }

  static Future<bool> markNotificationRead(String notificationId) async {
    try {
      final url = Uri.parse("$baseUrl/notifications/$notificationId/read");
      final res = await http.patch(url, headers: headers).timeout(const Duration(seconds: 5));
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      print("MARK NOTIFICATION READ ERROR: $e");
      return false;
    }
  }

  // =========================================================
  // ⏳ EQUIPMENT HISTORY / AUDIT LOGS APIs
  // =========================================================

  static Future<List<Map<String, dynamic>>> getEquipmentHistory(String equipmentId) async {
    try {
      final url = Uri.parse("$baseUrl/equipment/$equipmentId/history");
      final res = await http.get(url, headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        } else if (decoded is Map && decoded["data"] is List) {
          return List<Map<String, dynamic>>.from(decoded["data"]);
        } else if (decoded is Map && decoded["items"] is List) {
          return List<Map<String, dynamic>>.from(decoded["items"]);
        }
      }
      return [];
    } catch (e) {
      print("GET EQUIPMENT HISTORY ERROR: $e");
      return [];
    }
  }

  // =========================================================
  // 👥 ADMIN USER DIRECTORY & ACCESS APIs
  // =========================================================

  static Future<List<Map<String, dynamic>>> getAdminUsers() async {
    try {
      final url = Uri.parse("$baseUrl/admin/users");
      final res = await http.get(url, headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        } else if (decoded is Map && decoded["users"] is List) {
          return List<Map<String, dynamic>>.from(decoded["users"]);
        } else if (decoded is Map && decoded["data"] is List) {
          return List<Map<String, dynamic>>.from(decoded["data"]);
        }
      }
      return [];
    } catch (e) {
      print("GET ADMIN USERS ERROR: $e");
      return [];
    }
  }

  static Future<List<String>> getUserNavAccess(String userId) async {
    try {
      final url = Uri.parse("$baseUrl/admin/users/$userId/nav-access");
      final res = await http.get(url, headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded["modules"] is List) {
          return List<String>.from(decoded["modules"]);
        }
      }
      return [];
    } catch (e) {
      print("GET USER NAV ACCESS ERROR: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAdminModules() async {
    try {
      final url = Uri.parse("$baseUrl/admin/modules");
      final res = await http.get(url, headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        } else if (decoded is Map && decoded["modules"] is List) {
          return List<Map<String, dynamic>>.from(decoded["modules"]);
        } else if (decoded is Map && decoded["data"] is List) {
          return List<Map<String, dynamic>>.from(decoded["data"]);
        }
      }
      return [];
    } catch (e) {
      print("GET ADMIN MODULES ERROR: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getUserModules(String userId) async {
    try {
      final url = Uri.parse("$baseUrl/admin/users/$userId/modules");
      final res = await http.get(url, headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        } else if (decoded is Map && decoded["modules"] is List) {
          return List<Map<String, dynamic>>.from(decoded["modules"]);
        } else if (decoded is Map && decoded["data"] is List) {
          return List<Map<String, dynamic>>.from(decoded["data"]);
        }
      }
      return [];
    } catch (e) {
      print("GET USER MODULES ERROR: $e");
      return [];
    }
  }

  static Future<bool> assignUserModule(String userId, int moduleId, String accessLevel) async {
    try {
      final url = Uri.parse("$baseUrl/admin/users/$userId/modules");
      final res = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          "module_id": moduleId,
          "access_level": accessLevel,
        }),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print("ASSIGN USER MODULE ERROR: $e");
      return false;
    }
  }

  static Future<bool> deleteUserModule(String userId, int moduleId) async {
    try {
      final url = Uri.parse("$baseUrl/admin/users/$userId/modules/$moduleId");
      final res = await http.delete(url, headers: headers).timeout(const Duration(seconds: 10));
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      print("DELETE USER MODULE ERROR: $e");
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getCompanies() async {
    return _getList("$baseUrl/list/companies");
  }

  static Future<List<Map<String, dynamic>>> getLocations({String? companyId}) async {
    final query = companyId != null ? '?company_id=$companyId' : '';
    return _getList("$baseUrl/admin/locations$query");
  }

  static Future<bool> createLocation({
    required String companyId,
    required String locationName,
    required double latitude,
    required double longitude,
    required double geofenceRadiusMeters,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/admin/locations"),
        headers: headers,
        body: jsonEncode({
          "company_id": companyId,
          "location_name": locationName,
          "latitude": latitude,
          "longitude": longitude,
          "geofence_radius_meters": geofenceRadiusMeters,
        }),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print("CREATE LOCATION ERROR: $e");
      return false;
    }
  }

  static Future<bool> updateLocation(String id, Map<String, dynamic> data) async {
    try {
      final res = await http.patch(
        Uri.parse("$baseUrl/admin/locations/$id"),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (e) {
      print("UPDATE LOCATION ERROR: $e");
      return false;
    }
  }

  static Future<bool> deleteLocation(String id) async {
    try {
      final res = await http.delete(
        Uri.parse("$baseUrl/admin/locations/$id"),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (e) {
      print("DELETE LOCATION ERROR: $e");
      return false;
    }
  }

  static Future<bool> assignEquipmentLocation(String sosCode, String locationId) async {
    try {
      final res = await http.patch(
        Uri.parse("$baseUrl/admin/equipment/$sosCode/location"),
        headers: headers,
        body: jsonEncode({"location_id": locationId}),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (e) {
      print("ASSIGN EQUIPMENT LOCATION ERROR: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>> bulkAssignEquipmentLocations(
      List<Map<String, String>> assignments) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/admin/equipment/assign-locations"),
        headers: headers,
        body: jsonEncode(assignments),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200 || res.statusCode == 201) {
        try {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic>) {
            return {"success": true, ...decoded};
          }
        } catch (_) {}
        return {"success": true};
      }
      return {"success": false, "message": "Server error ${res.statusCode}"};
    } catch (e) {
      print("BULK ASSIGN LOCATION ERROR: $e");
      return {"success": false, "message": e.toString()};
    }
  }

  // No auth — called from mobile after scanning
  static Future<Map<String, dynamic>?> checkScanLocation({
    required String sosCode,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/scan/check-location"),
        headers: {"Content-Type": "application/json", "Accept": "application/json"},
        body: jsonEncode({
          "sos_code": sosCode,
          "latitude": latitude,
          "longitude": longitude,
        }),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) return decoded;
      }
      return null;
    } catch (e) {
      print("CHECK SCAN LOCATION ERROR: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getAdminUser(String userId) async {
    try {
      final url = Uri.parse("$baseUrl/admin/users/$userId");
      final res = await http.get(url, headers: headers).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey("user")) {
            return decoded["user"] as Map<String, dynamic>;
          }
          if (decoded.containsKey("data")) {
            return decoded["data"] as Map<String, dynamic>;
          }
          return decoded;
        }
      }
      return null;
    } catch (e) {
      print("GET ADMIN USER ERROR: $e");
      return null;
    }
  }
}

class http {
  static Future<origin_http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final res = await origin_http.get(url, headers: headers);
    if (res.statusCode == 401) ApiService.handleUnauthorized();
    return res;
  }

  static Future<origin_http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final res = await origin_http.post(url, headers: headers, body: body, encoding: encoding);
    if (res.statusCode == 401) ApiService.handleUnauthorized();
    return res;
  }

  static Future<origin_http.Response> patch(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final res = await origin_http.patch(url, headers: headers, body: body, encoding: encoding);
    if (res.statusCode == 401) ApiService.handleUnauthorized();
    return res;
  }

  static Future<origin_http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    final res = await origin_http.delete(url, headers: headers, body: body, encoding: encoding);
    if (res.statusCode == 401) ApiService.handleUnauthorized();
    return res;
  }
}
