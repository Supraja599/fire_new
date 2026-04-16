import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://124.123.110.52/app1/v1";

  // =========================================================
// 🔐 LOGIN API
// =========================================================
  static Future<Map<String, dynamic>?> login(
      String username, String password) async {
    try {
      final url = Uri.parse("$baseUrl/auth/login");

      print("LOGIN API CALLED: $url");

      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "username": username.trim(),
          "password": password.trim(),
        }),
      );

      print("LOGIN STATUS: ${res.statusCode}");
      print("LOGIN BODY: ${res.body}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        if (decoded is Map<String, dynamic>) {
          return decoded; // returns token + user
        }
      }

      return null;
    } catch (e) {
      print("LOGIN ERROR: $e");
      return null;
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
  // 🔍 SEARCH (DIRECT API - BEST)
  // =========================================================
  static Future<Map<String, dynamic>?> searchAny(String input) async {
    try {
      final id = normalize(input);

      final url = "$baseUrl/extinguishers/$id";

      print("==== SEARCH API ====");
      print("URL: $url");

      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      print("STATUS: ${res.statusCode}");
      print("BODY: ${res.body}");

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);

        // case 1: { item: {...} }
        if (decoded is Map && decoded.containsKey("item")) {
          return Map<String, dynamic>.from(decoded["item"]);
        }

        // case 2: direct object
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }

      if (res.statusCode == 404) return null;

      return null;
    } catch (e) {
      print("SEARCH ERROR: $e");
      return null;
    }
  }

  // =========================================================
  // 💾 INSERT / SAVE
  // =========================================================
  static Future<bool> insertVersion(Map<String, dynamic> data) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/status/insert-version"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: jsonEncode(data),
      );

      print("INSERT STATUS: ${res.statusCode}");

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print("INSERT ERROR: $e");
      return false;
    }
  }

  // =========================================================
  // 📊 ALERT SUMMARY
  // =========================================================
  static Future<Map<String, dynamic>?> getAlertSummary() async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/alerts/summary"))
          .timeout(const Duration(seconds: 5));

      print("ALERT SUMMARY STATUS: ${res.statusCode}");

      if (res.statusCode != 200) return null;

      final decoded = jsonDecode(res.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return null;
    } catch (e) {
      print("ALERT SUMMARY ERROR: $e");
      return null;
    }
  }

  // =========================================================
  // 📋 ALERT LIST
  // =========================================================
  static Future<List<Map<String, dynamic>>> getAlerts() =>
      _getList("$baseUrl/alerts");

  // =========================================================
  // 📊 DASHBOARD SUMMARY
  // =========================================================
  static Future<Map<String, dynamic>?> getSummary() async {
    try {
      final res = await http
          .get(Uri.parse("$baseUrl/summary"))
          .timeout(const Duration(seconds: 5));

      print("SUMMARY STATUS: ${res.statusCode}");

      if (res.statusCode != 200) return null;

      final decoded = jsonDecode(res.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return null;
    } catch (e) {
      print("SUMMARY ERROR: $e");
      return null;
    }
  }

  // =========================================================
  // 📦 EQUIPMENT LIST
  // =========================================================
  static Future<List<Map<String, dynamic>>> getAll() =>
      _getList("$baseUrl/extinguishers");

  // =========================================================
  // 📊 STATUS APIs
  // =========================================================
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

  // =========================================================
  // 📊 REPORT APIs
  // =========================================================

  // 🔹 Equipment Status Report
  static Future<List<Map<String, dynamic>>> getEquipmentStatus() =>
      _getList("$baseUrl/reports/equipment-status");

  // 🔹 Inspection Report (DATE RANGE)
  static Future<List<Map<String, dynamic>>> getInspections(
      String start, String end) =>
      _getList(
          "$baseUrl/reports/inspections?start_date=$start&end_date=$end");

  // 🔹 Expiry Report (if available)
  static Future<List<Map<String, dynamic>>> getExpiryReport() =>
      _getList("$baseUrl/reports/expiry");

  // 🔹 Service Report (if available)
  static Future<List<Map<String, dynamic>>> getServiceReport() =>
      _getList("$baseUrl/reports/service");

  // =========================================================
  // ⚙️ COMMON LIST HANDLER
  // =========================================================
  static Future<List<Map<String, dynamic>>> _getList(String url) async {
    try {
      print("CALLING API: $url");

      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      print("STATUS: ${res.statusCode}");

      if (res.statusCode != 200) return [];

      final decoded = jsonDecode(res.body);

      // case 1: { items: [...] }
      if (decoded is Map && decoded["items"] is List) {
        return List<Map<String, dynamic>>.from(decoded["items"]);
      }

      // case 2: { alerts: [...] }
      if (decoded is Map && decoded["alerts"] is List) {
        return List<Map<String, dynamic>>.from(decoded["alerts"]);
      }

      // case 3: direct list
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }

      return [];
    } catch (e) {
      print("API ERROR: $e");
      return [];
    }
  }
}