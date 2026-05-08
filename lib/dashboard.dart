import 'package:flutter/material.dart';
import 'package:fire_new/services/apiservice.dart';
import 'inspection.dart';
import 'analytics.dart';
import 'maintenance.dart';
import 'alerts.dart';
import 'planthealth.dart';
import 'reports.dart';
import 'services/apiservice.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const Color primaryRed = Color(0xFFD50000); // ✅ TRUE RED
  int total = 0, active = 0, health = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await ApiService.getSummary();
      if (mounted) {
        setState(() {
          total = s["total_units"] ?? s["total"] ?? 0;
          active = s["active_units"] ?? s["active"] ?? 0;
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
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount = 2;
    if (screenWidth > 900) {
      crossAxisCount = 4;
    } else if (screenWidth > 600) {
      crossAxisCount = 3;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                /// 🔴 HEADER (MATCHING USER'S ELTRIVE DESIGN)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: const BoxDecoration(
                    color: primaryRed,
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(80),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        "Extinguisher",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Company: Eltrive",
                        style: TextStyle(color: Colors.white70, fontSize: 20),
                      ),
                    ],
                  ),
                ),

                /// BODY
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        "What would you like to do?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        height: 3,
                        width: 50,
                        color: primaryRed,
                      ),
                      const SizedBox(height: 20),

                      /// GRID
                      Expanded(
                        child: GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: screenWidth > 600 ? 1.2 : 1.0,
                          children: [
                            _buildBox(context, "Analytics", Icons.query_stats, const AnalyticsPage()),
                            _buildBox(context, "Inspection", Icons.assignment_turned_in, const InspectionPage()),
                            _buildBox(context, "Maintenance", Icons.handyman, const MaintenancePage()),
                            _buildBox(context, "Alerts", Icons.notification_important, const AlertsPage()),
                            _buildBox(context, "Plant Health", Icons.health_and_safety, const PlantHealthPage()),
                            _buildBox(context, "Reports", Icons.assessment, const ReportsPage()),
                          ],
                        ),
                      ),

                      /// BOTTOM TEXT
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20, top: 10),
                        child: Text(
                          "Inspection Streak: ${isLoading ? "..." : "0 months"}",
                          style: const TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBox(BuildContext context, String title, IconData icon, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        decoration: BoxDecoration(
          color: primaryRed,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryRed.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 64),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
