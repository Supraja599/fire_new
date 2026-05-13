import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../widgets/equipment_list_page.dart';
import 'services/smoke_detector_api_service.dart';

class SmokeDetectorPlantHealthPage extends StatefulWidget {
  const SmokeDetectorPlantHealthPage({super.key});

  @override
  State<SmokeDetectorPlantHealthPage> createState() => _SmokeDetectorPlantHealthPageState();
}

class _SmokeDetectorPlantHealthPageState extends State<SmokeDetectorPlantHealthPage> {
  final api = SmokeDetectorApiService();
  int active = 0, service = 0, inspect = 0, expired = 0;
  List<Map<String, dynamic>> equipment = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([api.getSummary(), api.getEquipmentList()]);
      final summary = results[0] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        active = summary["active"] ?? 0;
        service = summary["needs_service"] ?? 0;
        inspect = summary["due_inspection"] ?? 0;
        expired = summary["expired"] ?? 0;
        equipment = results[1] as List<Map<String, dynamic>>;
        isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

    void _openStatusList(String type, String title, Color color) {
    final list = equipment.where((item) {
      final status = (item["status_bucket"]?.toString() ?? item["status"]?.toString() ?? "").toLowerCase().replaceAll("-", " ").trim();
      final target = type.toLowerCase().replaceAll("-", " ").trim();
      return status.contains(target) || target.contains(status);
    }).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EquipmentListPage(
          title: title,
          color: color,
          items: list,
          imagePath: 'assets/smoke_detector.png',
          fallbackIcon: Icons.smoke_free,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final total = active + service + inspect + expired;
    final maxY = [active, service, inspect, expired].reduce((a, b) => a > b ? a : b).toDouble() + 5;

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.blue), onPressed: () => Navigator.pop(context)),
        title: const Text("System Health Analytics", style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                _statusBox("ACTIVE", active, Colors.green.shade600, () => _openStatusList("active", "Active Detectors", Colors.green)),
                const SizedBox(width: 12),
                _statusBox("SERVICE", service, Colors.orange.shade700, () => _openStatusList("needs-service", "Needs Service", Colors.orange)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statusBox("INSPECT", inspect, Colors.blue.shade700, () => _openStatusList("due-inspection", "Due Inspection", Colors.blue)),
                const SizedBox(width: 12),
                _statusBox("EXPIRED", expired, Colors.red.shade700, () => _openStatusList("expired", "Expired Detectors", Colors.red)),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              height: 350,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.white, Colors.blue.shade50], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Device Performance Matrix", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1))),
                  const SizedBox(height: 30),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        maxY: maxY,
                        alignment: BarChartAlignment.spaceAround,
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35)),
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                            int idx = v.toInt();
                            if (idx < 0 || idx > 3) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                ["ACT", "SVC", "INS", "EXP"][idx],
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                              ),
                            );
                          })),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          _bar(0, active, Colors.green.shade400),
                          _bar(1, service, Colors.orange.shade400),
                          _bar(2, inspect, Colors.blue.shade400),
                          _bar(3, expired, Colors.red.shade400),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBox(String title, int value, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 25),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))]),
          child: Column(
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text("$value", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, int y, Color color) {
    return BarChartGroupData(x: x, barRods: [BarChartRodData(toY: y.toDouble(), color: color, width: 30, borderRadius: BorderRadius.circular(8), backDrawRodData: BackgroundBarChartRodData(show: true, toY: y.toDouble() + 5, color: color.withOpacity(0.1)))]);
  }
}
