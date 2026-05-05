import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'services/hydrant_api_service.dart';

class HydrantPlantHealthPage extends StatefulWidget {
  const HydrantPlantHealthPage({super.key});

  @override
  State<HydrantPlantHealthPage> createState() => _HydrantPlantHealthPageState();
}

class _HydrantPlantHealthPageState extends State<HydrantPlantHealthPage> {
  final api = HydrantApiService();

  int active = 0;
  int service = 0;
  int inspect = 0;
  int expired = 0;
  List<Map<String, dynamic>> equipment = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      api.getSummary(),
      api.getEquipmentList(),
    ]);

    if (!mounted) return;

    final summary = results[0] as Map<String, dynamic>;
    setState(() {
      active = summary["active"] ?? 0;
      service = summary["needs_service"] ?? 0;
      inspect = summary["due_inspection"] ?? 0;
      expired = summary["expired"] ?? 0;
      equipment = results[1] as List<Map<String, dynamic>>;
      isLoading = false;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF2E7D32);
      case 'needs-service':
        return const Color(0xFFEF6C00);
      case 'due-inspection':
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFFC62828);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Active';
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
    final maxValue = [active, service, inspect, expired]
        .reduce((a, b) => a > b ? a : b);

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Hydrant Plant Health"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _topCard('active', active),
                const SizedBox(width: 10),
                _topCard('needs-service', service),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _topCard('due-inspection', inspect),
                const SizedBox(width: 10),
                _topCard('expired', expired),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: BarChart(
                  BarChartData(
                    maxY: (maxValue + 1).toDouble(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          interval: 1,
                          getTitlesWidget: (value, _) => Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            const labels = ['Act', 'Svc', 'Ins', 'Exp'];
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                labels[value.toInt()],
                                style: const TextStyle(fontSize: 11),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      _bar(0, active, _statusColor('active')),
                      _bar(1, service, _statusColor('needs-service')),
                      _bar(2, inspect, _statusColor('due-inspection')),
                      _bar(3, expired, _statusColor('expired')),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topCard(String status, int count) {
    final color = _statusColor(status);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _HydrantStatusListPage(
                title: _statusLabel(status),
                color: color,
                items: equipment
                    .where((item) => item["status_bucket"]?.toString() == status)
                    .toList(),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                _statusLabel(status),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "$count",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, int value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value.toDouble(),
          width: 26,
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
      ],
    );
  }
}

class _HydrantStatusListPage extends StatelessWidget {
  final String title;
  final Color color;
  final List<Map<String, dynamic>> items;

  const _HydrantStatusListPage({
    required this.title,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EE),
      appBar: AppBar(backgroundColor: Colors.white, title: Text(title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final sosId =
              item["sos_code"] ?? item["serial_number"] ?? item["id"] ?? "-";
          final location =
              item["location_name"] ?? item["building_name"] ?? "Unknown";

          return GestureDetector(
            onTap: () => _showDetails(context, item, color),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 🖼️ REAL IMAGE IN LIST
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: AssetImage('assets/firehydrant.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SOS: ${sosId.toString()}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location.toString(),
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // 📩 BUTTON FEEL
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "SEND DETAILS",
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
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

  void _showDetails(BuildContext context, Map<String, dynamic> item, Color color) {
    final details = Map<String, dynamic>.from(item["details"] ?? {});
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.fire_hydrant_alt, color: color, size: 32),
              ),
              const SizedBox(height: 14),
              _detail("SOS ID", item["sos_code"]?.toString() ?? "-"),
              _detail("Location", item["location_name"]?.toString() ?? "-"),
              _detail("Building", item["building_name"]?.toString() ?? "-"),
              _detail("Zone", item["zone_name"]?.toString() ?? "-"),
              _detail("Status", item["status_bucket"]?.toString() ?? "-"),
              _detail("Pressure", details["operating_pressure_bar"]?.toString() ?? "-"),
              _detail("Flow Rate", details["flow_rate_lpm"]?.toString() ?? "-"),
              _detail("Hose Length", details["hose_length_m"]?.toString() ?? "-"),
              _detail("Next Inspection", item["next_inspection_due"]?.toString() ?? "-"),
            ],
          ),
        );
      },
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(flex: 6, child: Text(value)),
        ],
      ),
    );
  }
}
