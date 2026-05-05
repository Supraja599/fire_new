import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
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

  void _openStatusList(String status, String title, Color color) {
    final list = equipment.where((item) => item["status_bucket"]?.toString() == status).toList();
    Navigator.push(context, MaterialPageRoute(builder: (_) => _StatusListPage(title: title, color: color, items: list)));
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
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 10), child: Text(["ACT", "SVC", "INS", "EXP"][v.toInt()], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey))))),
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

class _StatusListPage extends StatelessWidget {
  final String title;
  final Color color;
  final List<Map<String, dynamic>> items;

  const _StatusListPage({required this.title, required this.color, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(title: Text(title), backgroundColor: Colors.white, elevation: 1),
      body: items.isEmpty
          ? const Center(child: Text("No Detectors Found"))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return GestureDetector(
                  onTap: () => _showDetails(context, item),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                    child: Row(
                      children: [
                        ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset('assets/smoke_detector.png', width: 50, height: 50, errorBuilder: (c, e, s) => Icon(Icons.smoke_free, color: color))),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.2))),
                              child: Text(
                                (item["sos_code"] ?? item["equipment_id"] ?? item["sos_id"] ?? item["id"] ?? "-").toString(),
                                style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 13, letterSpacing: 0.5),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(item["location_name"]?.toString() ?? "General Area", style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
                          ]),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showDetails(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(25),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text("DETECTOR DETAILS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.blue)),
              const Divider(),
              ...item.entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 4, child: Text(e.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))), Expanded(flex: 6, child: Text(e.value?.toString() ?? "-"))]))),
            ],
          ),
        ),
      ),
    );
  }
}
