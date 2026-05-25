import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';

class SCBAUnitsAlertsPage extends StatefulWidget {
  const SCBAUnitsAlertsPage({super.key});

  @override
  State<SCBAUnitsAlertsPage> createState() => _SCBAUnitsAlertsPageState();
}

class _SCBAUnitsAlertsPageState extends State<SCBAUnitsAlertsPage> {
  final api = ModuleApiService.scbaUnit;

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
          color: isSelected ? color : color.withOpacity(0.1),
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
    final sosId = item["sos_code"] ?? item["serial_number"] ?? item["id"] ?? "-";
    final location = item["building_name"] ?? item["location_name"] ?? "Unknown";
    final issue = item["alert_reason"] ?? item["alert_label"] ?? item["message"] ?? "Warning";

    return GestureDetector(
      onTap: () => _showDetails(item),
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
                  'assets/scba_unit.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(_levelIcon(level), color: color, size: 30),
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
                      issue,
                      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location,
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
                _detailRow("Building", (item["building_name"] ?? "-").toString()),
                _detailRow("Zone", (item["zone_name"] ?? "-").toString()),
                _detailRow("Next Inspection", (item["next_inspection_due"] ?? "-").toString()),
                _detailRow("Expiry", (item["expiry_date"] ?? "-").toString()),
                _detailRow("Status", (item["status_bucket"] ?? item["operational_status"] ?? "-").toString()),
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
