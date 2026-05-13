import 'package:fire_new/widgets/blinking_badge.dart';
import 'package:flutter/material.dart';
import 'package:fire_new/widgets/health_score_widget.dart';
import 'package:fire_new/services/apiservice.dart';
import 'maintaince.dart';
import 'alerts.dart';
import 'planthealth.dart';
import 'reports.dart';
import 'checklist.dart';
import 'scan.dart';
import 'services/api_service.dart';

class HeatDetectorDashboard extends StatefulWidget {
  const HeatDetectorDashboard({super.key});

  @override
  State<HeatDetectorDashboard> createState() => _HeatDetectorDashboardState();
}

class _HeatDetectorDashboardState extends State<HeatDetectorDashboard> {
  final api = HeatDetectorApiService();
  bool isLoading = true;
  int total = 0, active = 0, health = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final s = await api.getSummary();
      if (mounted && s != null) {
        setState(() {
          total = s["total_units"] ?? s["total"] ?? 0;
          active = s["active_units"] ?? s["active"] ?? 0;
          health = ApiService.calculateHealth(s);
          isLoading = false;
        });
      } else if (mounted) {
        setState(() => isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

    @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            // Minimal Header Section
            Container(
              padding: EdgeInsets.only(top: 25, bottom: 20, left: width * 0.05, right: width * 0.05),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (Navigator.canPop(context))
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
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
                          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 18),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Heat Detector",
                          style: TextStyle(
                            color: Colors.grey[900],
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Company Eltrive",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  HealthScoreWidget(health: health),
                ],
              ),
            ),
            const SizedBox(height: 5),
            // 🏆 MASTER EXECUTIVE RADIAL TELEMETRY BANNER
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 🚀 TOP TIER: Massive Radial Dial & Upgraded 3D Device Asset
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. LEFT: Gorgeous Circular Radial Indicator
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 100, // Upgraded size for dominance
                            height: 100, // Upgraded size for dominance
                            child: CircularProgressIndicator(
                              value: isLoading ? 0.0 : (health / 100.0),
                              strokeWidth: 9.5,
                              backgroundColor: Colors.grey.withValues(alpha: 0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isLoading 
                                  ? Colors.grey 
                                  : (health >= 85 
                                      ? const Color(0xFF1E8E3E) 
                                      : (health >= 60 ? const Color(0xFFFF8F00) : const Color(0xFFD50000))),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isLoading ? "--" : "${health}%",
                                style: TextStyle(
                                  fontSize: 23, // Huge executive look
                                  fontWeight: FontWeight.w900,
                                  color: Colors.grey[850],
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const Text(
                                "HEALTH",
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: Colors.grey,
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                      // 2. RIGHT: The HUGE, BEAUTIFUL Device Asset Image!
                      Hero(
                        tag: "hero_image_assets/heat_detector.png",
                        child: Image.asset(
                          "assets/heat_detector.png",
                          width: 115, // Exploded size!
                          height: 115, // Exploded size!
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 16),
                  // 📝 BOTTOM TIER: System Diagnostic Summary
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BlinkingActiveBadge(),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLoading
                                  ? "Accessing systems..."
                                  : (health >= 85 
                                      ? "Optimal Status Standing" 
                                      : (health >= 60 ? "Advisory Maintenance Required" : "Critical System Attention Required")),
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: isLoading 
                                    ? Colors.grey 
                                    : (health >= 85 
                                        ? const Color(0xFF1E8E3E) 
                                        : (health >= 60 ? const Color(0xFFFF8F00) : const Color(0xFFD50000))),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              isLoading
                                  ? "Decrypting real-time sensor telemetry streams..."
                                  : "Successfully validating $active active units currently operational out of ${total} deployed devices.",
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey[600],
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Action Grid
                        LayoutBuilder(
              builder: (context, constraints) {
                final double textScale = MediaQuery.textScalerOf(context).scale(1);
                int crossAxisCount = 3;
                
                double aspectRatio = (0.85 / textScale).clamp(0.6, 0.9);
                
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.04),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: aspectRatio,
                    children: [
                      _ActionCard("Plant Health", "assets/dashboard_icons/plant_health.png", const Color(0xFFD32F2F), const HeatDetectorPlantHealthPage(), "Score"),
                      _ActionCard("Alerts", "assets/dashboard_icons/alerts.png", const Color(0xFFD32F2F), const HeatDetectorAlertsPage(), "Critical"),
                      _ActionCard("Maintenance", "assets/dashboard_icons/maintenance.png", const Color(0xFFD32F2F), const HeatDetectorMaintenancePage(), "Service"),
                      _ActionCard("Reports", "assets/dashboard_icons/reports.png", const Color(0xFFD32F2F), const HeatDetectorReportsPage(), "Logs"),
                      _ActionCard("Checklist", Icons.library_books_rounded, const Color(0xFFD32F2F), const HeatDetectorChecklistPage(), "Forms"),
                      _ActionCard("Inspection", "assets/dashboard_icons/inspection.png", const Color(0xFFD32F2F), const HeatDetectorScanPage(), "Scan"),
                    ],
                  ),
                );
              },
            ),

            // Inspection Streak
            Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 20),
              child: Center(
                child: Text(
                  "Inspection Streak: 0 months",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: width * 0.035,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final dynamic imagePath; // dynamic to support both String assets and IconData safely!
  final Color color;
  final Widget page;
  final String? subtitle;

  const _ActionCard(this.title, this.imagePath, this.color, this.page, [this.subtitle]);

  @override
  Widget build(BuildContext context) {
    final String t = title.toLowerCase();
    List<Color> bgGradient = [Colors.white, Colors.white];
    Color shadowColor = Colors.grey.withValues(alpha: 0.1);
    Color borderColor = Colors.grey.withValues(alpha: 0.3);
    
    // Tailored accent borders and shadows for each card identity!
    if (t.contains("analytics")) {
      shadowColor = const Color(0xFF1A73E8).withValues(alpha: 0.18);
      borderColor = const Color(0xFF1A73E8).withValues(alpha: 0.65);
    } else if (t.contains("inspection")) {
      shadowColor = const Color(0xFF1E8E3E).withValues(alpha: 0.18);
      borderColor = const Color(0xFF1E8E3E).withValues(alpha: 0.65);
    } else if (t.contains("maintenance")) {
      shadowColor = const Color(0xFFF9AB00).withValues(alpha: 0.18);
      borderColor = const Color(0xFFF9AB00).withValues(alpha: 0.65);
    } else if (t.contains("alerts")) {
      shadowColor = const Color(0xFFD93025).withValues(alpha: 0.18);
      borderColor = const Color(0xFFD93025).withValues(alpha: 0.65);
    } else if (t.contains("plant health")) {
      shadowColor = const Color(0xFF0097A7).withValues(alpha: 0.18);
      borderColor = const Color(0xFF0097A7).withValues(alpha: 0.65);
    } else if (t.contains("reports")) {
      shadowColor = const Color(0xFF9334E6).withValues(alpha: 0.18);
      borderColor = const Color(0xFF9334E6).withValues(alpha: 0.65);
    } else if (t.contains("checklist") || t.contains("forms")) {
      // Tailored elegant deep indigo for checklist/forms
      shadowColor = const Color(0xFF3F51B5).withValues(alpha: 0.18);
      borderColor = const Color(0xFF3F51B5).withValues(alpha: 0.65);
    }
    
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: borderColor,
            width: 2.2, // Vibrant 2.2px definition from fire_extinguisher
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 6,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0, left: 12.0, right: 12.0, bottom: 4.0),
                  child: imagePath is IconData
                      ? FittedBox(
                          fit: BoxFit.contain,
                          child: Icon(
                            imagePath as IconData,
                            color: borderColor.withValues(alpha: 1.0),
                          ),
                        )
                      : Image.asset(
                          imagePath as String,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF202124),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
