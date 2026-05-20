import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fire_new/widgets/equipment_list_page.dart';
import 'package:fire_new/widgets/generic_plant_health_page.dart';

class GenericAnalyticsPage extends StatefulWidget {
  final String title;
  final String shortName;
  final String assetLabel;
  final dynamic apiService;
  final String imagePath;
  final IconData fallbackIcon;

  const GenericAnalyticsPage({
    super.key,
    required this.title,
    required this.shortName,
    required this.assetLabel,
    required this.apiService,
    required this.imagePath,
    required this.fallbackIcon,
  });

  @override
  State<GenericAnalyticsPage> createState() => _GenericAnalyticsPageState();
}

class _GenericAnalyticsPageState extends State<GenericAnalyticsPage> {
  List<Map<String, dynamic>> activeList = [];
  List<Map<String, dynamic>> serviceList = [];
  List<Map<String, dynamic>> inspectionList = [];
  List<Map<String, dynamic>> expiredList = [];

  int countActive = 0;
  int countService = 0;
  int countInspection = 0;
  int countExpired = 0;
  int countTotal = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);

    try {
      final res = await Future.wait([
        widget.apiService.getActive() as Future,
        widget.apiService.getUpcoming() as Future,
        widget.apiService.getNeedsService() as Future,
        widget.apiService.getDueInspection() as Future,
        widget.apiService.getExpired() as Future,
        widget.apiService.getSummary() as Future,
      ]);

      if (mounted) {
        setState(() {
          activeList = List<Map<String, dynamic>>.from(res[0] as Iterable? ?? []);
          final upcomingList = List<Map<String, dynamic>>.from(res[1] as Iterable? ?? []);
          activeList = [...activeList, ...upcomingList];
          serviceList = List<Map<String, dynamic>>.from(res[2] as Iterable? ?? []);
          inspectionList = List<Map<String, dynamic>>.from(res[3] as Iterable? ?? []);
          expiredList = List<Map<String, dynamic>>.from(res[4] as Iterable? ?? []);

          final s = res[5] as Map<String, dynamic>? ?? {};
          int upcoming = (s["upcoming"] ?? s["upcoming_units"] ?? 0) as int;
          int active = (s["active_units"] ?? s["active"] ?? s["active_loops"] ?? 0) as int;
          int service = (s["needs_service"] ?? s["needs_service_units"] ?? 0) as int;
          int inspection = (s["due_inspection"] ?? s["due_inspection_units"] ?? s["due_inspection_loops"] ?? 0) as int;
          int expired = (s["expired"] ?? s["expired_units"] ?? s["expired_loops"] ?? 0) as int;
          int total = (s["total"] ?? s["total_units"] ?? s["total_loops"] ?? s["total_extinguishers"] ?? 0) as int;

          // Dynamic suffix pattern matching for all 24 modules
          s.forEach((key, val) {
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
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ================= COLORS =================
  final activeColor = const Color(0xFF1E8E3E); // Modern Safety Green
  final serviceColor = const Color(0xFFFF8F00);
  final inspectionColor = const Color(0xFF1565C0);
  final expiredColor = const Color(0xFFD50000); // Modern True Red

  // ================= PIE DATA =================
  List<PieChartSectionData> getSections() {
    final data = [
      {"label": "Active", "value": countActive, "color": activeColor},
      {"label": "Need Service", "value": countService, "color": serviceColor},
      {"label": "Due Inspection", "value": countInspection, "color": inspectionColor},
      {"label": "Expired", "value": countExpired, "color": expiredColor},
    ];

    // If total is zero, show a subtle grey ring placeholder to prevent fl_chart rendering anomalies
    int totalCount = countTotal;
    if (totalCount == 0) {
      return [
        PieChartSectionData(
          value: 1.0,
          color: Colors.grey.shade300,
          radius: 85,
          title: "No Data\nAvailable",
          titleStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600]),
        )
      ];
    }

    return List.generate(data.length, (i) {
      final value = data[i]["value"] as int;
      final label = data[i]["label"] as String;

      // Only render slices that actually contain items to avoid messy overlaps on 0% slices
      if (value == 0) return PieChartSectionData(value: 0, showTitle: false);

      return PieChartSectionData(
        value: value.toDouble(),
        color: data[i]["color"] as Color,
        radius: 85, // Substantially enlarged
        title: "$label\n$value",
        titleStyle: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.55,
      );
    }).where((element) => element.value > 0).toList();
  }

  // ================= ICONS =================
  IconData getIcon(String type) {
    switch (type) {
      case "Active":
        return Icons.check_circle;
      case "Need Service":
        return Icons.handyman;
      case "Due Inspection":
        return Icons.fact_check;
      case "Expired":
        return Icons.warning;
      default:
        return Icons.circle;
    }
  }

  Color getColor(String type) {
    switch (type) {
      case "Active":
        return activeColor;
      case "Need Service":
        return serviceColor;
      case "Due Inspection":
        return inspectionColor;
      case "Expired":
        return expiredColor;
      default:
        return Colors.grey;
    }
  }

  // ================= TOTAL COUNT =================
  Widget totalCard() {
    int total = countTotal;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22), // Increased padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Larger premium rounding
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.assetLabel,
                  style: TextStyle(
                    fontSize: 15.5, // Enlarged size
                    fontWeight: FontWeight.w900, // Bold weight
                    color: Colors.grey[900],
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "$total",
                style: const TextStyle(
                  fontSize: 32, // Massively increased count size
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD50000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            thickness: 1.2,
            color: Colors.grey.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.analytics_outlined, size: 17, color: const Color(0xFFD50000).withValues(alpha: 0.7)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Real-time health surveillance, compliance logging, and operational readiness telemetry for all deployed ${widget.shortName} systems.",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= LIST DRILL-DOWN =================
  void openIdList(String label, List<Map<String, dynamic>> list) {
    final color = getColor(label);
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

  // ================= DRILL-DOWN GRID CARD =================
  Widget buildCard(String label, int count, List<Map<String, dynamic>> list) {
    final color = getColor(label);
    final icon = getIcon(label);

    return Expanded(
      child: GestureDetector(
        onTap: () => openIdList(label, list),
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16), // Substantially increased vertical padding
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24), // Enhanced rounding for larger size
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.95),
                color.withValues(alpha: 0.75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 7),
              )
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 44), // Increased from 38 for dominance
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16, // Increased from 15
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "$count",
                style: const TextStyle(
                  fontSize: 32, // Increased from 28
                  fontWeight: FontWeight.w900, // Maximized extra bold
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= MAIN UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFD50000), size: 16),
            ),
          ),
        ),
        title: Text(
          widget.title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFFD50000),
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GenericPlantHealthPage(
                      title: "${widget.shortName} Health",
                      shortName: widget.shortName,
                      apiService: widget.apiService,
                      imagePath: widget.imagePath,
                      fallbackIcon: widget.fallbackIcon,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E8E3E),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E8E3E).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      "HEALTH",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 25),

                    // ================= RING PIE CHART =================
                    SizedBox(
                      height: 285, // Increased from 240
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sections: getSections(),
                              centerSpaceRadius: 78, // Increased from 62
                              sectionsSpace: 3.5,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Dynamically load the 3D Asset thumbnail inside the Ring center!
                              Image.asset(
                                widget.imagePath,
                                width: 56, // Increased from 45
                                height: 56, // Increased from 45
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  widget.fallbackIcon,
                                  color: const Color(0xFFD50000),
                                  size: 36,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.shortName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 35),

                    // ================= TOTAL CONSOLE =================
                    totalCard(),

                    const SizedBox(height: 14),

                    // 🎉 NEW: Elegant Module Icon Info Card to fill empty space and describe the unit!
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.12),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          // 🎨 Custom-framed dynamic module icon
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD50000).withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Image.asset(
                              widget.imagePath,
                              width: 38,
                              height: 38,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                widget.fallbackIcon,
                                color: const Color(0xFFD50000),
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // 📝 Module descriptive telemetry copy
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${widget.shortName} Utility Hub",
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.grey[850],
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Comprehensive status oversight, live hazard monitoring, and real-time operational metrics for this emergency response equipment category.",
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[500],
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ================= METRICS ACTION GRID =================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              buildCard("Active", countActive, activeList),
                              buildCard("Need Service", countService, serviceList),
                            ],
                          ),
                          Row(
                            children: [
                              buildCard("Due Inspection", countInspection, inspectionList),
                              buildCard("Expired", countExpired, expiredList),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}
