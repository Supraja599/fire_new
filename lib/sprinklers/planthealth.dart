import 'package:fire_new/services/module_api_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../widgets/equipment_list_page.dart';

class SprinklerPlantHealthPage extends StatefulWidget {
  const SprinklerPlantHealthPage({super.key});

  @override
  State<SprinklerPlantHealthPage> createState() => _SprinklerPlantHealthPageState();
}

class _SprinklerPlantHealthPageState extends State<SprinklerPlantHealthPage> {
  final api = ModuleApiService.sprinkler;

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
        active = (summary["active"] ?? 0) + (summary["upcoming"] ?? summary["upcoming_units"] ?? 0);
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
          imagePath: 'assets/sprinkler.webp',
          fallbackIcon: Icons.water_drop,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Sprinkler Health System")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "Unable to load sprinkler summary.\n$error",
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Sprinkler Health System",
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
                  () => _openStatusList("active", "Active Sprinklers", Colors.green),
                ),
                const SizedBox(width: 8),
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
            const SizedBox(height: 10),
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
                const SizedBox(width: 8),
                _statusBox(
                  "Expired",
                  expired,
                  _percent(expired),
                  Colors.red,
                  () => _openStatusList("expired", "Expired Sprinklers", Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 18),
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
                    const Text(
                      "System Health Graph",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Tap any box above to open the SOS ID list for that status.",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
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
                                    style: const TextStyle(fontSize: 10),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "$value",
                style: const TextStyle(
                  fontSize: 20,
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
