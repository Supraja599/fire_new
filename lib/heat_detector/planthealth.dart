import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../widgets/equipment_list_page.dart';
import 'services/api_service.dart';

class HeatDetectorPlantHealthPage extends StatefulWidget {
  const HeatDetectorPlantHealthPage({super.key});
  @override
  State<HeatDetectorPlantHealthPage> createState() => _HeatDetectorPlantHealthPageState();
}

class _HeatDetectorPlantHealthPageState extends State<HeatDetectorPlantHealthPage> {
  final api = HeatDetectorApiService();
  int active = 0, service = 0, inspect = 0, expired = 0;
  List<Map<String, dynamic>> equipment = [];
  bool isLoading = true;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    try {
      final res = await Future.wait([api.getSummary(), api.getEquipmentList()]);
      final s = res[0] as Map<String, dynamic>;
      if (mounted) setState(() {
        active = s["active_units"] ?? s["active"] ?? 0;
        service = s["needs_service"] ?? 0;
        inspect = s["due_inspection"] ?? 0;
        expired = s["expired_units"] ?? s["expired"] ?? 0;
        equipment = res[1] as List<Map<String, dynamic>>;
        isLoading = false;
      });
    } catch (_) { if (mounted) setState(() => isLoading = false); }
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
          imagePath: "assets/heat_detector.png",
          fallbackIcon: Icons.medical_services,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(backgroundColor: Colors.white, elevation: 1, title: const Text("Health Analytics", style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Row(children: [_box("ACTIVE", active, Colors.green, () => _openStatusList("active", "Active Heat Detectors", Colors.green)), const SizedBox(width: 12), _box("SERVICE", service, Colors.orange, () => _openStatusList("needs-service", "Needs Service", Colors.orange))]),
          const SizedBox(height: 12),
          Row(children: [_box("INSPECT", inspect, Colors.blue, () => _openStatusList("due-inspection", "Due Inspection", Colors.blue)), const SizedBox(width: 12), _box("EXPIRED", expired, Colors.red, () => _openStatusList("expired", "Expired Heat Detectors", Colors.red))]),
          const SizedBox(height: 30),
          Container(
            height: 450, padding: const EdgeInsets.all(25), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Performance Matrix", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1))),
              const SizedBox(height: 40),
              Expanded(child: BarChart(BarChartData(
                maxY: (active + service + inspect + expired).toDouble() + 10,
                barGroups: [
                  _bar(0, active, Colors.green), _bar(1, service, Colors.orange), _bar(2, inspect, Colors.blue), _bar(3, expired, Colors.red),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                    int idx = v.toInt();
                    if (idx < 0 || idx > 3) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        ["ACTIVE", "SERVICE", "INSPECT", "EXPIRED"][idx],
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    );
                  })),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: true, drawVerticalLine: false), borderData: FlBorderData(show: false),
              ))),
            ]),
          ),
        ]),
      ),
    );
  }

  BarChartGroupData _bar(int x, int v, Color c) => BarChartGroupData(x: x, barRods: [BarChartRodData(toY: v.toDouble(), color: c, width: 28, borderRadius: BorderRadius.circular(8))]);
  Widget _box(String t, int v, Color c, VoidCallback onTap) => Expanded(child: GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 25), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: c.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]), child: Column(children: [Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(height: 8), Text("$v", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900))]))));
}

