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
        ApiService.getNeedsService(),
        ApiService.getDueInspection(),
        ApiService.getExpired(),
      ]);

      if (mounted) {
        setState(() {
          activeList = responses[0];
          serviceList = responses[1];
          inspectionList = responses[2];
          expiredList = responses[3];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      if (mounted) setState(() => isLoading = false);
    }
  }

  int get total => activeList.length + serviceList.length + inspectionList.length + expiredList.length;
  int get active => activeList.length;

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
          imagePath: 'assets/extinguisher.png',
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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const Text("Plant Health Dashboard", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 10),
                    Text(
                      "${(percent(active) * 100).toStringAsFixed(1)}%",
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
                      makeBar(0, activeList.length, Colors.green),
                      makeBar(1, serviceList.length, Colors.orange),
                      makeBar(2, inspectionList.length, Colors.blue),
                      makeBar(3, expiredList.length, Colors.red),
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
                buildRow("Active", activeList, Colors.green),
                buildRow("Needs Service", serviceList, Colors.orange),
                buildRow("Due Inspection", inspectionList, Colors.blue),
                buildRow("Expired", expiredList, Colors.red),
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

  Widget buildRow(String title, List<Map<String, dynamic>> list, Color color) {
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
              "${list.length} (${(percent(list.length) * 100).toStringAsFixed(1)}%)",
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