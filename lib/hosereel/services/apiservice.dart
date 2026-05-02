import 'dart:convert';
import 'package:http/http.dart' as http;

class HoseReelApiService {
  static const String baseUrl = "https://ehs.garrev.com/app1/v1";

  Map<String, String> get headers => {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };
// ============================================================
// 🔥 NEW FIXED ALERT API (BASED ON module_id=33)
// ============================================================
  Future<List<dynamic>> getHoseReelAlertsByModuleId() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/alerts?module_id=33"),
        headers: headers,
      );

      print("MODULE ID ALERTS STATUS: ${res.statusCode}");
      print("MODULE ID ALERTS BODY: ${res.body}");

      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body);

      if (data is List) return data;

      if (data is Map && data["items"] is List) return data["items"];

      if (data is Map && data["data"] is List) return data["data"];

      return [];
    } catch (e) {
      print("MODULE ID ALERTS ERROR: $e");
      return [];
    }
  }
  // ============================================================
  // 🔥 COMMON RESPONSE HANDLER
  // ============================================================
  dynamic _handle(http.Response res) {
    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("API ERROR ${res.statusCode}");
    }
  }

  // ============================================================
  // 🔥 GET ALL HOSE REEL DATA
  // ============================================================
  Future<List<dynamic>> getAllHoseReel() async {
    final res = await http.get(
      Uri.parse("$baseUrl/equipment?module_code=hose_reel"),
      headers: headers,
    );

    final data = _handle(res);

    if (data is Map && data["data"] is List) {
      return data["data"];
    } else if (data is List) {
      return data;
    } else {
      return [];
    }
  }

  // ============================================================
  // 🔥 GET ALERTS (ALL)
  // ============================================================
  Future<List<dynamic>> getHoseReelAlerts() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/alerts?module_code=hose_reel"),
        headers: headers,
      );

      print("ALERTS STATUS: ${res.statusCode}");
      print("ALERTS BODY: ${res.body}");

      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body);

      if (data is List) return data;

      if (data is Map && data["items"] is List) return data["items"];

      if (data is Map && data["data"] is List) return data["data"];

      return [];
    } catch (e) {
      print("ALERTS ERROR: $e");
      return [];
    }
  }

  // ============================================================
  // 🔥 GET ALERTS BY SEVERITY (CRITICAL / WARNING / INFO)
  // ============================================================
  Future<List<dynamic>> getAlertsBySeverity(String severity) async {
    try {
      final res = await http.get(
        Uri.parse(
          "$baseUrl/alerts?module_code=hose_reel&severity=$severity",
        ),
        headers: headers,
      );

      print("SEVERITY: $severity");
      print("STATUS: ${res.statusCode}");
      print("BODY: ${res.body}");

      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body);

      if (data is List) return data;

      if (data is Map && data["items"] is List) return data["items"];

      if (data is Map && data["data"] is List) return data["data"];

      return [];
    } catch (e) {
      print("SEVERITY ERROR: $e");
      return [];
    }
  }

  // ============================================================
  // 🔥 SUMMARY API
  // ============================================================
  Future<Map<String, dynamic>> getHoseReelSummary() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/alerts/summary?module_code=hose_reel"),
        headers: headers,
      );

      print("SUMMARY STATUS: ${res.statusCode}");
      print("SUMMARY BODY: ${res.body}");

      if (res.statusCode != 200) return {};

      final data = jsonDecode(res.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {};
    } catch (e) {
      print("SUMMARY ERROR: $e");
      return {};
    }
  }

  // ============================================================
  // 🔥 STATUS APIs
  // ============================================================
  Future<List<dynamic>> getByStatus(String status) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/status/$status?module_code=hose_reel"),
        headers: headers,
      );

      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body);

      if (data is List) return data;

      if (data is Map && data["items"] is List) return data["items"];

      if (data is Map && data["data"] is List) return data["data"];

      return [];
    } catch (e) {
      print("STATUS ERROR: $e");
      return [];
    }
  }

  // ============================================================
  // 🔥 COUNT HELPER
  // ============================================================
  Future<int> _getCount(String url) async {
    try {
      final res = await http.get(Uri.parse(url), headers: headers);

      print("URL: $url");
      print("STATUS: ${res.statusCode}");

      if (res.statusCode != 200) return 0;

      final data = jsonDecode(res.body);

      if (data is List) return data.length;

      if (data is Map && data["items"] is List) {
        return data["items"].length;
      }

      if (data is Map && data["data"] is List) {
        return data["data"].length;
      }

      return 0;
    } catch (e) {
      print("COUNT ERROR: $e");
      return 0;
    }
  }

  // ============================================================
  // 🔥 STATUS COUNTS
  // ============================================================
  Future<int> getActiveCount() =>
      _getCount("$baseUrl/status/active?module_code=hose_reel");

  Future<int> getNeedsServiceCount() =>
      _getCount("$baseUrl/status/needs-service?module_code=hose_reel");

  Future<int> getDueInspectionCount() =>
      _getCount("$baseUrl/status/due-inspection?module_code=hose_reel");

  Future<int> getExpiredCount() =>
      _getCount("$baseUrl/status/expired?module_code=hose_reel");

  // ============================================================
  // 🔥 UPCOMING INSPECTIONS
  // ============================================================
  Future<List<dynamic>> getUpcoming() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/upcoming?module_code=hose_reel"),
        headers: headers,
      );

      print("UPCOMING STATUS: ${res.statusCode}");
      print("UPCOMING BODY: ${res.body}");

      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body);

      if (data is List) return data;

      if (data is Map && data["items"] is List) return data["items"];

      if (data is Map && data["data"] is List) return data["data"];

      return [];
    } catch (e) {
      print("UPCOMING ERROR: $e");
      return [];
    }
  }
}