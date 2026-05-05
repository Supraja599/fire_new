import 'package:flutter/material.dart';
import 'maintaince.dart';
import 'alerts.dart';
import 'planthealth.dart';
import 'reports.dart';
import 'checklist.dart';
import 'inspection.dart';

import 'services/smoke_detector_api_service.dart';

class SmokeDetectorDashboard extends StatefulWidget {
  const SmokeDetectorDashboard({super.key});

  @override
  State<SmokeDetectorDashboard> createState() => _SmokeDetectorDashboardState();
}

class _SmokeDetectorDashboardState extends State<SmokeDetectorDashboard> {
  static const Color primary = Color(0xFF1976D2);
  static const Color accent = Color(0xFFBBDEFB);

  final api = SmokeDetectorApiService();
  bool isLoading = true;
  int deviceCount = 0;
  int efficiency = 98; // Default fallback

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await api.syncModuleData();
      final summary = await api.getSummary();
      if (mounted) {
        setState(() {
          deviceCount = summary["active"] ?? 0;
          final risk = (summary["needs_service"] ?? 0) + (summary["expired"] ?? 0);
          if (deviceCount + risk > 0) {
            efficiency = ((deviceCount / (deviceCount + risk)) * 100).toInt();
          }
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 28, color: primary),
                  ),
                  const Spacer(),
                  const Text(
                    "Air Quality & Smoke Safety",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  const Spacer(),
                  const SizedBox(width: 28), // balance for close icon
                ],
              ),
            ),

            // FEATURED CARD
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Environment Safe",
                              style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "Smoke Detection Network",
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1), height: 1.1),
                            ),
                          ],
                        ),
                      ),
                      Image.asset(
                        'assets/smoke_detector.png',
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const Icon(Icons.lens_blur, color: primary, size: 60),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statusTag(isLoading ? "Loading..." : "$deviceCount Devices Online", Icons.check_circle, Colors.green),
                      _statusTag(isLoading ? "..." : "$efficiency% Efficiency", Icons.speed, primary),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // BIG ACTION CARDS (2x3 GRID)
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.1,
                children: [
                  _BigActionCard("Plant Health", Icons.analytics_outlined, const SmokeDetectorPlantHealthPage(), Colors.green.shade600, "Device Health"),
                  _BigActionCard("Safety Alerts", Icons.notification_important_outlined, const SmokeDetectorAlertsPage(), Colors.red.shade600, "Active Alerts"),
                  _BigActionCard("Maintenance", Icons.build_circle_outlined, const SmokeDetectorMaintenancePage(), Colors.orange.shade700, "Services"),
                  _BigActionCard("Reports", Icons.summarize_outlined, const SmokeDetectorReportsPage(), Colors.purple.shade600, "History"),
                  _BigActionCard("Checklist", Icons.fact_check_outlined, const SmokeDetectorChecklistPage(), Colors.teal.shade700, "Forms"),
                  _BigActionCard("Inspection", Icons.camera_enhance_outlined, const SmokeDetectorInspectionPage(), Colors.blue.shade700, "Scan"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusTag(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 4)]),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _BigActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget page;
  final Color color;
  final String subtitle;

  const _BigActionCard(this.title, this.icon, this.page, this.color, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10)),
            BoxShadow(color: Colors.white, blurRadius: 10, offset: const Offset(-5, -5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
              child: Icon(icon, color: color, size: 32),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0D47A1), fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
