import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../widgets/equipment_list_page.dart';

import 'services/apiservice.dart';

class HoseReelPlantHealthPage extends StatefulWidget {
  const HoseReelPlantHealthPage({super.key});

  @override
  State<HoseReelPlantHealthPage> createState() => _HoseReelPlantHealthPageState();
}

class _HoseReelPlantHealthPageState extends State<HoseReelPlantHealthPage> {
  final api = HoseReelApiService();

  int active = 0;
  int service = 0;
  int inspection = 0;
  int expired = 0;
  List<Map<String, dynamic>> equipment = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        api.getSummary(),
        api.getEquipmentList(),
      ]);

      final summary = results[0] as Map<String, dynamic>;
      final items = results[1] as List<Map<String, dynamic>>;

      if (!mounted) return;

      setState(() {
        active = summary["active"] ?? 0;
        service = summary["needs_service"] ?? 0;
        inspection = summary["due_inspection"] ?? 0;
        expired = summary["expired"] ?? 0;
        equipment = items;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  int get total => active + service + inspection + expired;

  double _percent(int value) => total == 0 ? 0 : value / total;

  double get _maxY {
    final values = [active, service, inspection, expired];
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    if (maxValue <= 0) return 10;
    return (maxValue + 5).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    void _openStatusList(String status, String title, Color color) {
        
        final list = equipment
            .where((item) => item["status_bucket"]?.toString() == status)
            .toList();
    
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EquipmentListPage(
              title: title,
              color: color,
              items: list,
              imagePath: 'assets/hosereel.png',
              fallbackIcon: Icons.fire_hydrant_alt,
            ),
          ),
        );
      }

    
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Hose Reel Health System")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "Unable to load hose reel summary.\n$error",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Hose Reel Health System",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                _statusBox(
                  "Active",
                  active,
                  _percent(active),
                  Colors.green,
                  () => _openStatusList("active", "Active Hose Reels", Colors.green),
                ),
                SizedBox(width: 8),
                _statusBox(
                  "Service",
                  service,
                  _percent(service),
                  Colors.orange,
                  () => _openStatusList(
                    "needs-service",
                    "Needs Service",
                    Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                _statusBox(
                  "Inspect",
                  inspection,
                  _percent(inspection),
                  Colors.blue,
                  () => _openStatusList(
                    "due-inspection",
                    "Due Inspection",
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 8),
                _statusBox(
                  "Expired",
                  expired,
                  _percent(expired),
                  Colors.red,
                  () => _openStatusList("expired", "Expired Hose Reels", Colors.red),
                ),
              ],
            ),
            SizedBox(height: 18),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "System Health Graph",
                      style: TextStyle(
                        fontSize: width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Tap any box above to open the SOS ID list for that status.",
                      style: TextStyle(fontSize: width * 0.03, color: Colors.grey),
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          maxY: _maxY,
                          alignment: BarChartAlignment.spaceAround,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: _maxY / 5,
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: _maxY / 5,
                                getTitlesWidget: (value, _) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: TextStyle(fontSize: width * 0.025),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, _) {
                                  const labels = [
                                    "Active",
                                    "Service",
                                    "Inspect",
                                    "Expired",
                                  ];
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
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          barGroups: [
                            _bar(0, active, Colors.green),
                            _bar(1, service, Colors.orange),
                            _bar(2, inspection, Colors.blue),
                            _bar(3, expired, Colors.red),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBox(
    String title,
    int value,
    double percent,
    Color color,
    VoidCallback onTap,
  ) {
    final double width = MediaQuery.of(context).size.width;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.3), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                "$value",
                style: TextStyle(
                  fontSize: width * 0.05,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${(percent * 100).toStringAsFixed(1)}%",
                style: const TextStyle(color: Colors.white70),
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
          width: 24,
          borderRadius: BorderRadius.circular(10),
          color: color,
        ),
      ],
    );
  }
}

