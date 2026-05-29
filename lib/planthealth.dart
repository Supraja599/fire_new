import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'widgets/equipment_list_page.dart';
import 'services/apiservice.dart';

class PlantHealthPage extends StatefulWidget {
  const PlantHealthPage({super.key});

  @override
  State<PlantHealthPage> createState() => _PlantHealthPageState();
}

class _PlantHealthPageState extends State<PlantHealthPage> {
  List<Map<String, dynamic>> activeList = [];
  List<Map<String, dynamic>> serviceList = [];
  List<Map<String, dynamic>> inspectionList = [];
  List<Map<String, dynamic>> expiredList = [];
  
  int countActive = 0;
  int countService = 0;
  int countInspection = 0;
  int countExpired = 0;
  int countTotal = 0;
  int health = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    try {
      final responses = await Future.wait([
        ApiService.getActive(),
        ApiService.getUpcoming(),
        ApiService.getNeedsService(),
        ApiService.getDueInspection(),
        ApiService.getExpired(),
        ApiService.getSummary(),
      ]);

      if (mounted) {
        setState(() {
          final List<Map<String, dynamic>> rawActive = List<Map<String, dynamic>>.from(responses[0] as Iterable? ?? []);
          final List<Map<String, dynamic>> rawUpcoming = List<Map<String, dynamic>>.from(responses[1] as Iterable? ?? []);
          activeList = [...rawActive, ...rawUpcoming];
          serviceList = List<Map<String, dynamic>>.from(responses[2] as Iterable? ?? []);
          inspectionList = List<Map<String, dynamic>>.from(responses[3] as Iterable? ?? []);
          expiredList = List<Map<String, dynamic>>.from(responses[4] as Iterable? ?? []);
          
          final summary = responses[5] as Map<String, dynamic>? ?? {};
          int upcoming = (summary["upcoming"] ?? summary["upcoming_units"] ?? 0) as int;
          int active = (summary["active_units"] ?? summary["active"] ?? summary["active_loops"] ?? 0) as int;
          int service = (summary["needs_service"] ?? summary["needs_service_units"] ?? 0) as int;
          int inspection = (summary["due_inspection"] ?? summary["due_inspection_units"] ?? summary["due_inspection_loops"] ?? 0) as int;
          int expired = (summary["expired"] ?? summary["expired_units"] ?? summary["expired_loops"] ?? 0) as int;
          int total = (summary["total"] ?? summary["total_units"] ?? summary["total_loops"] ?? summary["total_extinguishers"] ?? 0) as int;

          // Dynamic suffix pattern matching for all 24 modules
          summary.forEach((key, val) {
            if (val is num) {
              final intValue = val.toInt();
              final lowerKey = key.toLowerCase();
              if (lowerKey.contains("active") && lowerKey != "active") active = intValue;
              if (lowerKey.contains("total") && lowerKey != "total") total = intValue;
              if (lowerKey.contains("expired") && lowerKey != "expired") expired = intValue;
              if (lowerKey.contains("service") && lowerKey != "needs_service") service = intValue;
              if (lowerKey.contains("inspection") && lowerKey != "due_inspection") inspection = intValue;
              if (lowerKey.contains("upcoming") && lowerKey != "upcoming") upcoming = intValue;
            }
          });

          active = active + upcoming;
          total = active + service + inspection + expired;

          countActive = active;
          countService = service;
          countInspection = inspection;
          countExpired = expired;
          countTotal = total;

          if (countTotal > 0) {
            health = ((countActive / countTotal) * 100).toInt();
          } else {
            health = 100;
          }
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) setState(() => isLoading = false);
    }
  }

  int get total => countTotal;
  int get active => countActive;

  double percent(int value) => total == 0 ? 0 : value / total;

  double get maxY {
    if (total == 0) return 100;
    return ((total / 100).ceil() * 100).toDouble();
  }

  void openIdList(String title, List<Map<String, dynamic>> list, Color color) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EquipmentListPage(
          title: title,
          items: list,
          color: color,
          imagePath: 'assets/extinguisher.webp',
          fallbackIcon: Icons.fire_extinguisher,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 55, bottom: 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      health >= 90
                          ? const Color(0xFF1E8E3E)
                          : health >= 80
                              ? const Color(0xFFFF8F00)
                              : const Color(0xFFD50000),
                      health >= 90
                          ? const Color(0xFF52B76D)
                          : health >= 80
                              ? const Color(0xFFFFB300)
                              : const Color(0xFFFF5252),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (health >= 90
                              ? const Color(0xFF1E8E3E)
                              : health >= 80
                                  ? const Color(0xFFFF8F00)
                                  : const Color(0xFFD50000))
                          .withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    const Text("Plant Health Dashboard", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 10),
                    Text(
                      "$health%",
                      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text("$active Active • $total Total Units", style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              Positioned(
                top: 40,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    alignment: BarChartAlignment.spaceAround,
                    gridData: FlGridData(show: true, horizontalInterval: maxY / 5, drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: maxY / 5,
                          getTitlesWidget: (value, _) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                          reservedSize: 35,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            const titles = ["Active", "Service", "Inspect", "Expired"];
                            return Text(titles[value.toInt()], style: const TextStyle(fontSize: 12));
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    barGroups: [
                      makeBar(0, countActive, const Color(0xFF1E8E3E)),
                      makeBar(1, countService, const Color(0xFFFF8F00)),
                      makeBar(2, countInspection, const Color(0xFF1565C0)),
                      makeBar(3, countExpired, const Color(0xFFD50000)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                buildRow("Active", countActive, activeList, const Color(0xFF1E8E3E)),
                buildRow("Needs Service", countService, serviceList, const Color(0xFFFF8F00)),
                buildRow("Due Inspection", countInspection, inspectionList, const Color(0xFF1565C0)),
                buildRow("Expired", countExpired, expiredList, const Color(0xFFD50000)),
              ],
            ),
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  BarChartGroupData makeBar(int x, int value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: value.toDouble(), width: 30, borderRadius: BorderRadius.circular(12), color: color),
      ],
    );
  }

  Widget buildRow(String title, int count, List<Map<String, dynamic>> list, Color color) {
    return GestureDetector(
      onTap: () => openIdList(title, list, color),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Expanded(child: Row(children: [
              Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 12),
              Text(title),
            ])),
            Text(
              "$count (${(percent(count) * 100).toStringAsFixed(1)}%)",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}