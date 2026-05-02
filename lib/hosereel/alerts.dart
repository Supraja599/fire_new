import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HoseReelAlertsPage extends StatefulWidget {
  const HoseReelAlertsPage({super.key});
  @override
  State<HoseReelAlertsPage> createState() => _HoseReelAlertsPageState();
}

// ============================================================
// 🔥 MODEL (ROBUST / AUTO FIX)
// ============================================================
class HoseReelAlert {
  final String id;
  final String plantName;
  final String issue;
  final int level;
  final Map<String, dynamic> raw;

  HoseReelAlert({
    required this.id,
    required this.plantName,
    required this.issue,
    required this.level,
    required this.raw,
  });

  factory HoseReelAlert.fromJson(Map<String, dynamic> json) {
    String safe(dynamic v) => v?.toString() ?? "Unknown";
    int parseLevel(dynamic v) {
      final value = v.toString().toLowerCase();

      if (value.contains("critical") || value == "3") return 3;
      if (value.contains("warning") || value == "2") return 2;
      if (value.contains("info") || value == "1") return 1;

      return int.tryParse(value) ?? 1;
    }

    return HoseReelAlert(
      id: safe(json["id"] ?? json["alert_id"] ?? json["equipment_id"]),
      plantName: safe(json["equipment_name"] ??
          json["equipmentName"] ??
          json["name"] ??
          json["location_name"]),
      issue: safe(json["alert_reason"] ??
          json["message"] ??
          json["description"] ??
          json["alert"]),
      level: parseLevel(json["alert_level"] ??
          json["severity"] ??
          json["status"] ??
          json["level"]),
      raw: json,
    );
  }
}

class _HoseReelAlertsPageState extends State<HoseReelAlertsPage> {
  static const String baseUrl = "https://ehs.garrev.com/app1/v1";

  final headers = {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };

  List<HoseReelAlert> all = [];
  List<HoseReelAlert> filtered = [];

  bool loading = true;
  int? selectedLevel;
  int? expandedIndex;

  // ============================================================
  // 🔥 SAFE API LOADER (FIXED)
  // ============================================================
  Future<void> loadData() async {
    setState(() => loading = true);

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/alerts?module_id=33"),
        headers: headers,
      );

      print("STATUS: ${res.statusCode}");
      print("BODY: ${res.body}");

      if (res.statusCode != 200) {
        setState(() => loading = false);
        return;
      }

      final data = jsonDecode(res.body);

      List list = [];

      if (data is List) {
        list = data;
      } else if (data is Map) {
        if (data["data"] is List) list = data["data"];
        else if (data["items"] is List) list = data["items"];
        else if (data["result"] is List) list = data["result"];
      }

      final parsed = list
          .map((e) => HoseReelAlert.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      setState(() {
        all = parsed;
        filtered = parsed;
        loading = false;
      });
    } catch (e) {
      print("ERROR: $e");
      setState(() {
        all = [];
        filtered = [];
        loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ============================================================
  // 🔥 FILTER
  // ============================================================
  void filter(int? level) {
    setState(() {
      selectedLevel = level;
      expandedIndex = null;

      filtered = level == null
          ? all
          : all.where((e) => e.level == level).toList();
    });
  }

  // ============================================================
  // 🔥 COLORS
  // ============================================================
  Color color(int l) {
    if (l == 3) return Colors.red;
    if (l == 2) return Colors.orange;
    return Colors.blue;
  }

  String label(int l) {
    if (l == 3) return "CRITICAL";
    if (l == 2) return "WARNING";
    return "INFO";
  }

  // ============================================================
  // 🔥 TOP BUTTONS (FIXED COUNTS)
  // ============================================================
  Widget topBtn(String title, int level) {
    final selected = selectedLevel == level;
    final count = all.where((e) => e.level == level).length;

    return Expanded(
      child: GestureDetector(
        onTap: () => filter(selected ? null : level),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? color(level) : color(level).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color(level)),
          ),
          child: Text(
            "$title\n$count",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : color(level),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 🔥 ITEM (EXPAND INSIDE SAME SCREEN)
  // ============================================================
  Widget item(HoseReelAlert a, int index) {
    final expanded = expandedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          expandedIndex = expanded ? null : index;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color(a.level)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, color: color(a.level)),
                const SizedBox(width: 10),
                Expanded(child: Text("ID: ${a.id}")),
                Icon(expanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down),
              ],
            ),
            const SizedBox(height: 5),
            Text(a.plantName),
            Text(a.issue),

            if (expanded) ...[
              const Divider(),
              Text("LEVEL: ${label(a.level)}"),
              const SizedBox(height: 5),
              Text("FULL DATA:"),
              Text(a.raw.toString()),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🔥 UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            child: Row(
              children: [
                topBtn("CRITICAL", 3),
                topBtn("WARNING", 2),
                topBtn("INFO", 1),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? const Center(child: Text("No alerts found"))
                : RefreshIndicator(
              onRefresh: loadData,
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (c, i) => item(filtered[i], i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}