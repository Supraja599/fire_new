import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/equipment_list_page.dart';
class AlarmPanelPlantHealthPage extends StatefulWidget {
  const AlarmPanelPlantHealthPage({super.key});

  @override
  State<AlarmPanelPlantHealthPage> createState() => _AlarmPanelPlantHealthPageState();
}

class _AlarmPanelPlantHealthPageState extends State<AlarmPanelPlantHealthPage> {
  final api = ModuleApiService.alarmPanel;
  Map<String, dynamic> summary = {};
  List<Map<String, dynamic>> equipment = [];
  bool isLoading = true;

  int active = 0, faults = 0, inspect = 0, expired = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final summaryData = await api.getSummary();
      final list = await api.getEquipmentList();
      if (!mounted) return;
      setState(() {
        summary = summaryData;
        equipment = list;
        active = (summaryData["active"] ?? 0) + (summaryData["upcoming"] ?? summaryData["upcoming_units"] ?? 0);
        faults = summaryData["needs_service"] ?? 0;
        inspect = summaryData["due_inspection"] ?? 0;
        expired = summaryData["expired"] ?? 0;
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
      if (target == "active") return status == "active" || status == "upcoming";
      return status.contains(target) || target.contains(status);
    }).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EquipmentListPage(
          title: title,
          color: color,
          items: list,
          imagePath: "assets/alarm_panel.png",
          fallbackIcon: Icons.developer_board,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxY = [active, faults, inspect, expired].reduce((a, b) => a > b ? a : b).toDouble() + 5;

    return Scaffold(
      backgroundColor: const Color(0xFFFDE8E8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFFB71C1C)), onPressed: () => Navigator.pop(context)),
        title: const Text("System Health Analytics", style: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold)),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFB71C1C)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    _statusBox("ACTIVE", active, Colors.green.shade600, () => _openStatusList("active", "Active Loops", Colors.green)),
                    const SizedBox(width: 12),
                    _statusBox("FAULTS", faults, Colors.red.shade700, () => _openStatusList("faults", "System Faults", Colors.red)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _statusBox("INSPECT", inspect, Colors.blue.shade700, () => _openStatusList("inspect", "Due Inspection", Colors.blue)),
                    const SizedBox(width: 12),
                    _statusBox("EXPIRED", expired, Colors.orange.shade700, () => _openStatusList("expired", "Battery Expired", Colors.orange)),
                  ],
                ),
                const SizedBox(height: 30),
                Container(
                  height: 350,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.white, Colors.red.shade50], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Loop Performance Matrix", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFB71C1C))),
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
                                ["ACT", "FLT", "INS", "EXP"][idx],
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
                              _bar(1, faults, Colors.red.shade400),
                              _bar(2, inspect, Colors.blue.shade400),
                              _bar(3, expired, Colors.orange.shade400),
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
