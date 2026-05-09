import 'package:flutter/material.dart';
import 'package:fire_new/widgets/health_score_widget.dart';
import '../inspection.dart';
import '../analytics.dart';
import '../maintenance.dart';
import '../alerts.dart';
import '../planthealth.dart';
import '../reports.dart';
import '../services/apiservice.dart';
import 'services/api_service.dart';

class FireExtinguisherDashboard extends StatefulWidget {
  const FireExtinguisherDashboard({super.key});

  @override
  State<FireExtinguisherDashboard> createState() => _FireExtinguisherDashboardState();
}

class _FireExtinguisherDashboardState extends State<FireExtinguisherDashboard> {
  static const Color primary = Color(0xFFD32F2F);
  
  final api = FireExtinguisherApiService();
  int activeUnits = 0, needsService = 0, total = 0, health = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await api.getSummary();
      if (mounted) {
        setState(() {
          activeUnits = s["active_units"] ?? s["active"] ?? 0;
          needsService = (s["needs_service"] ?? 0) + (s["expired"] ?? 0) + (s["needs-service"] ?? 0);
          total = s["total_units"] ?? s["total"] ?? (activeUnits + needsService);
          health = ApiService.calculateHealth(s);
          isLoading = false;
        });
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
            // Red Header Section
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFFC62828)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              padding: EdgeInsets.symmetric(vertical: 30, horizontal: width * 0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "Fire Extinguisher",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: width * 0.07,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Company Eltrive",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: width * 0.04,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  HealthScoreWidget(health: health),
                ],
              ),
            ),
             const SizedBox(height: 10),

            // Action Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final double textScale = MediaQuery.textScalerOf(context).scale(1);
                int crossAxisCount = width >= 600 ? 3 : 2;
                
                double aspectRatio = 0.95;
                if (crossAxisCount == 2) {
                   aspectRatio = (0.95 / textScale).clamp(0.7, 0.95);
                } else {
                   aspectRatio = (1.05 / textScale).clamp(0.8, 1.05);
                }
                
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: aspectRatio,
                    children: [
                      _ActionCard("Analytics", Icons.bar_chart_rounded, primary, const AnalyticsPage(), "Trends"),
                      _ActionCard("Inspection", Icons.fact_check_rounded, primary, const InspectionPage(), "Scan"),
                      _ActionCard("Maintenance", Icons.construction_rounded, primary, const MaintenancePage(), "Service"),
                      _ActionCard("Alerts", Icons.emergency_rounded, primary, const AlertsPage(), "Critical"),
                      _ActionCard("Plant Health", Icons.monitor_heart_rounded, primary, const PlantHealthPage(), "Score"),
                      _ActionCard("Reports", Icons.history_edu_rounded, primary, const ReportsPage(), "Logs"),
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
  final IconData icon;
  final Color color;
  final Widget page;
  final String subtitle;

  const _ActionCard(this.title, this.icon, this.color, this.page, this.subtitle);

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        padding: EdgeInsets.all(width * 0.05),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: width * 0.1),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: width * 0.04,
                ),
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: width * 0.03,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

