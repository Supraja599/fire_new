import 'package:flutter/material.dart';

import 'services/apiservice.dart';

class HoseReelAlertsPage extends StatefulWidget {
  const HoseReelAlertsPage({super.key});

  @override
  State<HoseReelAlertsPage> createState() => _HoseReelAlertsPageState();
}

class _HoseReelAlertsPageState extends State<HoseReelAlertsPage> {
  final api = HoseReelApiService();

  List<Map<String, dynamic>> alerts = [];
  bool isLoading = true;
  int? selectedLevel;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final data = await api.getAlerts();

    if (!mounted) return;

    setState(() {
      alerts = data;
      isLoading = false;
    });
  }

  int _levelOf(Map<String, dynamic> item) {
    final raw = (item["level"] ?? item["alert_level"] ?? "1").toString();
    return int.tryParse(raw) ?? 1;
  }

  List<Map<String, dynamic>> get _filtered {
    if (selectedLevel == null) return alerts;
    return alerts.where((item) => _levelOf(item) == selectedLevel).toList();
  }

  Color _levelColor(int level) {
    if (level == 3) return const Color(0xFFD32F2F);
    if (level == 2) return const Color(0xFFF57C00);
    return const Color(0xFFFBC02D);
  }

  String _levelText(int level) {
    if (level == 3) return "Emergency";
    if (level == 2) return "Critical";
    return "Warning";
  }

  IconData _levelIcon(int level) {
    if (level == 3) return Icons.local_fire_department_rounded;
    if (level == 2) return Icons.warning_rounded;
    return Icons.info_rounded;
  }

  Widget _topButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(child: _buildButton(3)),
          Expanded(child: _buildButton(2)),
          Expanded(child: _buildButton(1)),
        ],
      ),
    );
  }

  Widget _buildButton(int level) {
    final color = _levelColor(level);
    final isSelected = selectedLevel == level;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLevel = selectedLevel == level ? null : level;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Icon(
              _levelIcon(level),
              color: isSelected ? Colors.white : color,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              _levelText(level),
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

  Widget _alertCard(Map<String, dynamic> item) {
    final level = _levelOf(item);
    final color = _levelColor(level);
    final code = item["sos_code"] ?? item["equipment_id"] ?? item["id"] ?? "-";
    final location = item["building_name"] ??
        item["location_name"] ??
        item["zone_name"] ??
        "Unknown";
    final issue = item["alert_reason"] ??
        item["alert_label"] ??
        item["message"] ??
        "No issue message";

    return GestureDetector(
      onTap: () => _showDetails(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_levelIcon(level), color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location.toString(),
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    issue.toString(),
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

  void _showDetails(Map<String, dynamic> item) {
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
                _row("ID", item["id"]),
                _row("SOS Code", item["sos_code"]),
                _row("Location", item["location_name"]),
                _row("Building", item["building_name"]),
                _row("Zone", item["zone_name"]),
                _row("Alert Level", _levelText(_levelOf(item))),
                _row("Reason", item["alert_reason"] ?? item["message"]),
                _row("Status", item["status_bucket"] ?? item["operational_status"]),
                _row("Next Inspection", item["next_inspection_due"]),
                _row("Expiry", item["expiry_date"]),
              ],
            ),
          ),
        );
      },
    );
  }

  DataRow _row(String key, dynamic value) {
    return DataRow(
      cells: [
        DataCell(Text(key)),
        DataCell(Text(value?.toString() ?? "-")),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          SafeArea(child: _topButtons()),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadAlerts,
                    child: list.isEmpty
                        ? const Center(child: Text("No Alerts Found"))
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: list.map(_alertCard).toList(),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
