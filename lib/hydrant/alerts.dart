import 'package:flutter/material.dart';

import 'services/hydrant_api_service.dart';

class HydrantAlertsPage extends StatefulWidget {
  const HydrantAlertsPage({super.key});

  @override
  State<HydrantAlertsPage> createState() => _HydrantAlertsPageState();
}

class _HydrantAlertsPageState extends State<HydrantAlertsPage> {
  final api = HydrantApiService();
  String? selectedSeverity;
  List<Map<String, dynamic>> alerts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await api.getAlerts();
    if (!mounted) return;
    setState(() {
      alerts = data;
      isLoading = false;
    });
  }

  String _severityOf(Map<String, dynamic> item) {
    final level = int.tryParse(
      (item["level"] ?? item["alert_level"] ?? "1").toString(),
    ) ??
        1;
    if (level >= 3) return 'critical';
    if (level == 2) return 'warning';
    return 'info';
  }

  List<Map<String, dynamic>> get _list {
    if (selectedSeverity == null) return alerts;
    return alerts.where((item) => _severityOf(item) == selectedSeverity).toList();
  }

  Color _color(String severity) {
    switch (severity) {
      case 'critical':
        return const Color(0xFFC62828);
      case 'warning':
        return const Color(0xFFEF6C00);
      default:
        return const Color(0xFF1565C0);
    }
  }

  String _label(String severity) {
    switch (severity) {
      case 'critical':
        return 'Critical';
      case 'warning':
        return 'Warning';
      default:
        return 'Info';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EE),
      body: Column(
        children: [
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(child: _chip('critical')),
                  Expanded(child: _chip('warning')),
                  Expanded(child: _chip('info')),
                ],
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: _list.length,
                    itemBuilder: (context, index) {
                      final item = _list[index];
                      final severity = _severityOf(item);
                      final color = _color(severity);
                      return GestureDetector(
                        onTap: () => _showDetails(context, item, color, severity),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: color.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.warning_amber_rounded, color: color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (item["alert_reason"] ??
                                              item["message"] ??
                                              "Hydrant alert")
                                          .toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text((item["sos_code"] ?? item["equipment_id"] ?? "-").toString()),
                                    Text(
                                      (item["location_name"] ??
                                              item["building_name"] ??
                                              "Unknown")
                                          .toString(),
                                      style: TextStyle(color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _label(severity),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String severity) {
    final color = _color(severity);
    final selected = selectedSeverity == severity;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSeverity = selected ? null : severity;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color),
        ),
        child: Center(
          child: Text(
            _label(severity),
            style: TextStyle(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(
    BuildContext context,
    Map<String, dynamic> item,
    Color color,
    String severity,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, color: color, size: 40),
              const SizedBox(height: 10),
              _row("SOS ID", (item["sos_code"] ?? item["equipment_id"] ?? "-").toString()),
              _row("Severity", _label(severity)),
              _row("Location", (item["location_name"] ?? item["building_name"] ?? "-").toString()),
              _row("Status", (item["status_bucket"] ?? item["operational_status"] ?? "-").toString()),
              _row("Date", (item["created_at"] ?? item["next_inspection_due"] ?? "-").toString()),
              _row("Message", (item["alert_reason"] ?? item["message"] ?? "-").toString()),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String a, String b) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(a, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(flex: 6, child: Text(b)),
        ],
      ),
    );
  }
}
