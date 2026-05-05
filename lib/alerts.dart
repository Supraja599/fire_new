import 'package:flutter/material.dart';
import 'services/apiservice.dart';

class AlertPlant {
  final String plantName;
  final String issue;
  final int level;
  final Map<String, dynamic> raw;

  AlertPlant({
    required this.plantName,
    required this.issue,
    required this.level,
    required this.raw,
  });

  factory AlertPlant.fromJson(Map<String, dynamic> json) {
    return AlertPlant(
      plantName: json['building_name']?.toString() ??
          json['location_name']?.toString() ??
          'Unknown',
      issue: json['alert_label']?.toString() ??
          json['alert_reason']?.toString() ??
          'No Issue',
      level: json['alert_level'] ?? 1,
      raw: json,
    );
  }
}

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  List<AlertPlant> alerts = [];
  bool isLoading = true;
  int? selectedLevel;

  @override
  void initState() {
    super.initState();
    loadAlerts();
  }

  Future<void> loadAlerts() async {
    final alertData = await ApiService.getAlerts();
    final expiredData = await ApiService.getExpired();

    // 🏷️ Add a label to expired items so they show up clearly
    final normalizedExpired = expiredData.map((e) {
      e["alert_label"] = "EXPIRED";
      e["alert_level"] = 3; // Emergency level for expired items
      return e;
    }).toList();

    setState(() {
      final combined = [...alertData, ...normalizedExpired];
      alerts = combined.map((e) => AlertPlant.fromJson(e)).toList();
      isLoading = false;
    });
  }

  List<AlertPlant> get filtered {
    if (selectedLevel == null) return alerts;
    return alerts.where((e) => e.level == selectedLevel).toList();
  }

  Color levelColor(int level) {
    if (level == 3) return const Color(0xFFD32F2F);
    if (level == 2) return const Color(0xFFF57C00);
    return const Color(0xFFFBC02D);
  }

  String levelText(int level) {
    if (level == 3) return "Emergency";
    if (level == 2) return "Critical";
    return "Warning";
  }

  IconData levelIcon(int level) {
    if (level == 3) return Icons.local_fire_department_rounded;
    if (level == 2) return Icons.warning_rounded;
    return Icons.info_rounded;
  }

  // ✅ UPDATED TOP BAR WITH BACK BUTTON
  Widget topButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black12,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          // 🔙 BACK BUTTON
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),

          // FILTER BUTTONS
          Expanded(child: buildButton(3)),
          Expanded(child: buildButton(2)),
          Expanded(child: buildButton(1)),
        ],
      ),
    );
  }

  Widget buildButton(int level) {
    final color = levelColor(level);
    final isSelected = selectedLevel == level;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLevel = level;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Icon(
              levelIcon(level),
              color: isSelected ? Colors.white : color,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              levelText(level),
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget alertCard(AlertPlant p) {
    final color = levelColor(p.level);
    final sosId = p.raw["sos_code"] ?? p.raw["serial_number"] ?? p.raw["id"] ?? "-";

    return GestureDetector(
      onTap: () => showDetails(p.raw),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: Container(
                width: 90,
                height: 100,
                color: color.withOpacity(0.08),
                child: Image.asset(
                  'assets/extinguisher.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(levelIcon(p.level), color: color, size: 30),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SOS ID: $sosId",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.issue,
                      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.plantName,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            )
          ],
        ),
      ),
    );
  }

  void showDetails(Map item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 40),
                const SizedBox(height: 14),
                const Text(
                  "Alert Details",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                _detailRow("SOS ID", (item["sos_code"] ?? item["serial_number"] ?? item["id"] ?? "-").toString()),
                _detailRow("Issue", (item["alert_label"] ?? item["alert_reason"] ?? "Warning").toString()),
                _detailRow("Location", (item["location_name"] ?? "-").toString()),
                _detailRow("Type", (item["extinguisher_type"] ?? "-").toString()),
                _detailRow("Building", (item["building_name"] ?? "-").toString()),
                _detailRow("Next Inspection", (item["next_inspection_due"] ?? "-").toString()),
                _detailRow("Expiry", (item["expiry_date"] ?? "-").toString()),
                _detailRow("Status", (item["operational_status"] ?? "-").toString()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String a, String b) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: Text(a, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 6, child: Text(b)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          SafeArea(child: topButtons()),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: loadAlerts,
              child: list.isEmpty
                  ? const Center(child: Text("No Alerts Found"))
                  : ListView(
                padding: const EdgeInsets.all(16),
                children: list.map(alertCard).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}