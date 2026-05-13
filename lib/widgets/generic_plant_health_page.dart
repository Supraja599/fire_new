import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'equipment_list_page.dart';

class GenericPlantHealthPage extends StatefulWidget {
  final String title;
  final String shortName;
  final dynamic apiService;
  final String imagePath;
  final IconData fallbackIcon;

  const GenericPlantHealthPage({
    super.key,
    required this.title,
    required this.shortName,
    required this.apiService,
    required this.imagePath,
    required this.fallbackIcon,
  });

  @override
  State<GenericPlantHealthPage> createState() => _GenericPlantHealthPageState();
}

class _GenericPlantHealthPageState extends State<GenericPlantHealthPage> {
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
      // Explicit casting to Future for strong-mode safety
      final responses = await Future.wait([
        widget.apiService.getActive() as Future,
        widget.apiService.getNeedsService() as Future,
        widget.apiService.getDueInspection() as Future,
        widget.apiService.getExpired() as Future,
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
      debugPrint("Plant Health Fetch Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  int get total => activeList.length + serviceList.length + inspectionList.length + expiredList.length;
  int get active => activeList.length;

  double percent(int value) => total == 0 ? 0 : value / total;

  // Smart, adaptive headroom generator for maximum bar presence
  double get maxY {
    int maxVal = [activeList.length, serviceList.length, inspectionList.length, expiredList.length].reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return 10;
    return (maxVal * 1.25).ceilToDouble();
  }

  void openIdList(String label, List<Map<String, dynamic>> list, Color color) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EquipmentListPage(
          title: "$label ${widget.shortName}",
          items: list,
          color: color,
          imagePath: widget.imagePath,
          fallbackIcon: widget.fallbackIcon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final healthPercentage = percent(active) * 100;
    
    // Lock Health color to the beautiful, premium brand Green!
    const Color healthColor = Color(0xFF2E7D32); 

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Hero Gradient Score Banner
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(top: 65, bottom: 35),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF2E7D32), // Dark Forest Brand Green
                              Color(0xFF66BB6A), // Light Grass Brand Green
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(36),
                            bottomRight: Radius.circular(36),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: healthColor.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              "${widget.shortName} Health Dashboard".toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "${healthPercentage.toStringAsFixed(1)}%",
                              style: const TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$active Active • $total Total Units Deployed",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 45,
                        left: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Graphical Bar Chart Console
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      height: 320, // Explicit static height for reliable scrolling layout
                      padding: const EdgeInsets.only(top: 25, bottom: 12, left: 12, right: 22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          )
                        ],
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: BarChart(
                        BarChartData(
                          maxY: maxY,
                          alignment: BarChartAlignment.spaceAround,
                          gridData: FlGridData(
                            show: true,
                            horizontalInterval: (maxY / 4).clamp(1, double.infinity),
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey.withValues(alpha: 0.15),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: (maxY / 4).clamp(1, double.infinity),
                                getTitlesWidget: (value, _) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                reservedSize: 32,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                getTitlesWidget: (value, _) {
                                  const titles = ["Active", "Service", "Inspect", "Expired"];
                                  if (value.toInt() >= 0 && value.toInt() < titles.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        titles[value.toInt()],
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    );
                                  }
                                  return const Text("");
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          barGroups: [
                            makeBar(0, activeList.length, const Color(0xFF1E8E3E)),
                            makeBar(1, serviceList.length, const Color(0xFFFF8F00)),
                            makeBar(2, inspectionList.length, const Color(0xFF1565C0)),
                            makeBar(3, expiredList.length, const Color(0xFFD50000)),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Metric List Console
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        buildRow("Active", activeList, const Color(0xFF1E8E3E)),
                        buildRow("Needs Service", serviceList, const Color(0xFFFF8F00)),
                        buildRow("Due Inspection", inspectionList, const Color(0xFF1565C0)),
                        buildRow("Expired", expiredList, const Color(0xFFD50000)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
    );
  }

  BarChartGroupData makeBar(int x, int value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value.toDouble(),
          width: 32,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          color: color,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY,
            color: color.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }

  Widget buildRow(String label, List<Map<String, dynamic>> list, Color color) {
    return GestureDetector(
      onTap: () => openIdList(label, list, color),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.08),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[800],
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              "${list.length} (${(percent(list.length) * 100).toStringAsFixed(1)}%)",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: color,
                fontSize: 14.5,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
