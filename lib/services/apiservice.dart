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
      if (token!= null) "Authorization": "Bearer $token",
    };
  }


  // =========================================================
  // 🔐 LOGIN API
  // =========================================================
  static Future<Map<String, dynamic>?> login(
      String username, String password) async {
    try {
      final url = Uri.parse("$baseUrl/auth/login");

      final res = await http
          .post(
        url,
        headers: headers,
        body: jsonEncode({
          "username": username.trim(),
          "password": password.trim(),
        }),
      )
          .timeout(const Duration(seconds: 10));

      print("LOGIN STATUS: ${res.statusCode}");
      print("LOGIN BODY: ${res.body}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        if (decoded is Map<String, dynamic>) {
          // 🔐 Save token
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
  static const String checklistUrl =
      "$baseUrl/checklists/fire_extinguisher";

  static Future<List<Map<String, dynamic>>> getFireChecklist() async {
    try {
      final res = await http
          .get(Uri.parse(checklistUrl), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return [];

      final decoded = jsonDecode(res.body);

      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }

      if (decoded is Map && decoded["items"] is List) {
        return List<Map<String, dynamic>>.from(decoded["items"]);
      }

      return [];
    } catch (e) {
      print("CHECKLIST GET ERROR: $e");
      return [];
    }
  }

  static Future<bool> updateFireChecklist(
      List<Map<String, dynamic>> data) async {
    try {
      final res = await http
          .post(
        Uri.parse(checklistUrl),
        headers: headers,
        body: jsonEncode(data),
      )
          .timeout(const Duration(seconds: 10));

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print("CHECKLIST POST ERROR: $e");
      return false;
    }
  }

  // ================= NORMALIZE =================
  static String normalize(String value) {
    return value
        .trim()
        .replaceAll("\n", "")
        .replaceAll(" ", "")
        .replaceAll("-", "")
        .toUpperCase();
  }

  // =========================================================
  // 🔍 SEARCH
  // =========================================================
  static Future<Map<String, dynamic>?> searchAny(String input) async {
    try {
      final id = normalize(input);
      final url = "$baseUrl/extinguishers/$id";

      final res = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        if (decoded is Map && decoded.containsKey("item")) {
          return Map<String, dynamic>.from(decoded["item"]);
        }

        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }

      return null;
    } catch (e) {
      print("SEARCH ERROR: $e");
      return null;
    }
  }

  // =========================================================
  // 💾 INSERT
  // =========================================================
  static Future<bool> insertVersion(Map<String, dynamic> data) async {
    try {
      final res = await http
          .post(
        Uri.parse("$baseUrl/status/insert-version"),
        headers: headers,
        body: jsonEncode(data),
      )
          .timeout(const Duration(seconds: 10));

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print("INSERT ERROR: $e");
      return false;
    }
  }

  // =========================================================
  // 📊 COMMON GET LIST HANDLER
  // =========================================================
  static Future<List<Map<String, dynamic>>> _getList(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return [];

      final decoded = jsonDecode(res.body);

      if (decoded is Map && decoded["items"] is List) {
        return List<Map<String, dynamic>>.from(decoded["items"]);
      }

      if (decoded is Map && decoded["alerts"] is List) {
        return List<Map<String, dynamic>>.from(decoded["alerts"]);
      }

      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }

      return [];
    } catch (e) {
      print("API ERROR: $e");
      return [];
    }
  }

  // ================= APIs =================
  static Future<List<Map<String, dynamic>>> getAlerts() =>
      _getList("$baseUrl/alerts");

  static Future<Map<String, dynamic>?> getSummary() async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/summary"), headers: headers)
          .timeout(const Duration(seconds: 5));

      if (res.statusCode != 200) return null;

      return jsonDecode(res.body);
    } catch (e) {
      print("SUMMARY ERROR: $e");
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getAll() =>
      _getList("$baseUrl/extinguishers");

  static Future<List<Map<String, dynamic>>> getActive() =>
      _getList("$baseUrl/status/active");

  static Future<List<Map<String, dynamic>>> getNeedsService() =>
      _getList("$baseUrl/status/needs-service");

  static Future<List<Map<String, dynamic>>> getDueInspection() =>
      _getList("$baseUrl/status/due-inspection");

  static Future<List<Map<String, dynamic>>> getExpired() =>
      _getList("$baseUrl/status/expired");

  static Future<List<Map<String, dynamic>>> getUpcoming() =>
      _getList("$baseUrl/status/upcoming");

  static Future<List<Map<String, dynamic>>> getEquipmentStatus() =>
      _getList("$baseUrl/reports/equipment-status");

  static Future<List<Map<String, dynamic>>> getInspections(
      String start, String end) =>
      _getList(
          "$baseUrl/reports/inspections?start_date=$start&end_date=$end");

  static Future<List<Map<String, dynamic>>> getExpiryReport() =>
      _getList("$baseUrl/reports/expiry");

  static Future<List<Map<String, dynamic>>> getServiceReport() =>
      _getList("$baseUrl/reports/service");
  static Future<void> syncAllExtinguishersToLocal() async {
    try {
      final list = await getAll();

      print("SYNC START: ${list.length} items found");

      for (var item in list) {
        final id = normalize(item['id']?.toString() ?? '');

        if (id.isEmpty) continue;

        await LocalDB.insert(id, item);
      }

      print("✅ SYNC COMPLETE: ${list.length} items stored in SQLite");
    } catch (e) {
      print("❌ SYNC ERROR: $e");
    }
  }
  static Future<bool> sendToServer(String data) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/save"),
        headers: headers,
        body: jsonEncode({"data": data}),
      );

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}










