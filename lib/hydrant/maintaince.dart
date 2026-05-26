import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';

class HydrantMaintenancePage extends StatefulWidget {
  const HydrantMaintenancePage({super.key});

  @override
  State<HydrantMaintenancePage> createState() => _HydrantMaintenancePageState();
}

class _HydrantMaintenancePageState extends State<HydrantMaintenancePage> {
  final api = ModuleApiService.hydrant;
  List<Map<String, dynamic>> records = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    final equipment = await api.getEquipmentList();
    final filtered = equipment.where((item) {
      final status = item["status_bucket"]?.toString().toLowerCase() ?? "";
      // 🔥 EXPIRED ITEMS SHOULD GO TO ALERTS, NOT MAINTENANCE
      return (status == "needs-service" || status == "due-inspection") && status != "expired";
    }).toList()
      ..sort((a, b) {
        final aDate = _parseDate(a["next_inspection_due"]?.toString());
        final bDate = _parseDate(b["next_inspection_due"]?.toString());
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });

    if (!mounted) return;
    setState(() {
      records = filtered;
      isLoading = false;
    });
  }

  Color _colorFor(String status) {
    switch (status) {
      case 'needs-service':
        return const Color(0xFFEF6C00);
      case 'due-inspection':
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFFC62828);
    }
  }

  String _labelFor(String status) {
    switch (status) {
      case 'needs-service':
        return 'Service';
      case 'due-inspection':
        return 'Inspect';
      default:
        return 'Expired';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Hydrant Maintenance"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final item = records[index];
                final status = item["status_bucket"]?.toString() ?? "expired";
                final color = _colorFor(status);
                final details = Map<String, dynamic>.from(item["details"] ?? {});

                return GestureDetector(
                  onTap: () => _showDetails(context, item, color),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(20),
                          ),
                          child: Container(
                            width: 96,
                            height: 108,
                            color: color.withValues(alpha: 0.08),
                            child: Image.asset(
                              'assets/firehydrant.webp',
                              fit: BoxFit.contain,
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
                                  (item["sos_code"] ?? item["id"] ?? "-").toString(),
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (item["location_name"] ??
                                          item["building_name"] ??
                                          "Unknown")
                                      .toString(),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _chip(
                                      _labelFor(status),
                                      color,
                                    ),
                                    _chip(
                                      "Next ${item["next_inspection_due"] ?? "-"}",
                                      Colors.grey.shade700,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Pressure: ${details["operating_pressure_bar"] ?? "-"} bar",
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, Map<String, dynamic> item, Color color) {
    final details = Map<String, dynamic>.from(item["details"] ?? {});
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
              Icon(Icons.build_circle_outlined, color: color, size: 40),
              const SizedBox(height: 10),
              _row("SOS ID", (item["sos_code"] ?? "-").toString()),
              _row("Location", (item["location_name"] ?? "-").toString()),
              _row("Pressure", (details["operating_pressure_bar"] ?? "-").toString()),
              _row("Flow Rate", (details["flow_rate_lpm"] ?? "-").toString()),
              _row("Hose Length", (details["hose_length_m"] ?? "-").toString()),
              _row("Remarks", (item["remarks"] ?? item["status_bucket"] ?? "-").toString()),
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
