import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../widgets/equipment_list_page.dart';

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
      active = (summary["active"] ?? 0) + (summary["upcoming"] ?? summary["upcoming_units"] ?? 0);
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
              builder: (_) => EquipmentListPage(
                title: _statusLabel(status),
                color: color,
                items: equipment
                    .where((item) {
                      final bucket = (item["status_bucket"]?.toString() ?? item["status"]?.toString() ?? "").toLowerCase();
                      if (status == "active") return bucket == "active" || bucket == "upcoming";
                      return bucket.contains(status.toLowerCase());
                    })
                    .toList(),
                imagePath: 'assets/firehydrant.png',
                fallbackIcon: Icons.fire_hydrant_alt,
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
