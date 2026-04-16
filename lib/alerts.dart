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
    final data = await ApiService.getAlerts();

    setState(() {
      alerts = data.map((e) => AlertPlant.fromJson(e)).toList();
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

    return GestureDetector(
      onTap: () => showDetails(p.raw),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.5)),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(levelIcon(p.level), color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.plantName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.issue,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
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
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: DataTable(
              columnSpacing: 20,
              columns: const [
                DataColumn(label: Text("Field")),
                DataColumn(label: Text("Value")),
              ],
              rows: [
                row("ID", item["id"]),
                row("Barcode", item["barcode"]),
                row("Equipment Code", item["equipment_code"]),
                row("Type", item["extinguisher_type"]),
                row("Location", item["location_name"]),
                row("Building", item["building_name"]),
                row("Next Inspection", item["next_inspection_due"]),
                row("Expiry", item["expiry_date"]),
                row("Status", item["operational_status"]),
                row("Alert Level", item["alert_label"]),
                row("Days Overdue", item["days_overdue"]),
              ],
            ),
          ),
        );
      },
    );
  }

  DataRow row(String key, dynamic value) {
    return DataRow(cells: [
      DataCell(Text(key)),
      DataCell(Text(value?.toString() ?? "-")),
    ]);
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