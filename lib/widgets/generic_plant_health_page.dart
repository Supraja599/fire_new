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
      // Explicit casting to Future for strong-mode safety
      final responses = await Future.wait([
        widget.apiService.getActive() as Future,
        widget.apiService.getNeedsService() as Future,
        widget.apiService.getDueInspection() as Future,
        widget.apiService.getExpired() as Future,
        widget.apiService.getUpcoming() as Future,
        widget.apiService.getSummary() as Future,
      ]);

      if (mounted) {
        setState(() {
          final List<Map<String, dynamic>> rawActive = List<Map<String, dynamic>>.from(responses[0] as Iterable? ?? []);
          final List<Map<String, dynamic>> rawUpcoming = List<Map<String, dynamic>>.from(responses[4] as Iterable? ?? []);
          activeList = [...rawActive, ...rawUpcoming];
          serviceList = List<Map<String, dynamic>>.from(responses[1] as Iterable? ?? []);
          inspectionList = List<Map<String, dynamic>>.from(responses[2] as Iterable? ?? []);
          expiredList = List<Map<String, dynamic>>.from(responses[3] as Iterable? ?? []);
          
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
      debugPrint("Plant Health Fetch Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  int get total => countTotal;
  int get active => countActive;

  double percent(int value) => total == 0 ? 0 : value / total;

  // Smart, adaptive headroom generator for maximum bar presence
  double get maxY {
    int maxVal = [countActive, countService, countInspection, countExpired].reduce((a, b) => a > b ? a : b);
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
    // Dynamic brand semantic gradient colors
    Color startColor;
    Color endColor;
    if (health >= 85) {
      startColor = const Color(0xFF1E8E3E);
      endColor = const Color(0xFF52B76D);
    } else if (health >= 60) {
      startColor = const Color(0xFFFF8F00);
      endColor = const Color(0xFFFFB300);
    } else {
      startColor = const Color(0xFFD50000);
      endColor = const Color(0xFFFF5252);
    }

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
                          gradient: LinearGradient(
                            colors: [
                              startColor,
                              endColor,
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
                              color: startColor.withOpacity(0.2),
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
                              "$health%",
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
                                color: Colors.white.withOpacity(0.85),
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
                            makeBar(0, countActive, const Color(0xFF1E8E3E)),
                            makeBar(1, countService, const Color(0xFFFF8F00)),
                            makeBar(2, countInspection, const Color(0xFF1565C0)),
                            makeBar(3, countExpired, const Color(0xFFD50000)),
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
                        buildRow("Active", countActive, activeList, const Color(0xFF1E8E3E)),
                        buildRow("Needs Service", countService, serviceList, const Color(0xFFFF8F00)),
                        buildRow("Due Inspection", countInspection, inspectionList, const Color(0xFF1565C0)),
                        buildRow("Expired", countExpired, expiredList, const Color(0xFFD50000)),
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

  Widget buildRow(String label, int count, List<Map<String, dynamic>> list, Color color) {
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
              "$count (${(percent(count) * 100).toStringAsFixed(1)}%)",
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
