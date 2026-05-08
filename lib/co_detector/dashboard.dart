import 'package:flutter/material.dart';
import 'package:fire_new/services/apiservice.dart';
import 'maintaince.dart';
import 'alerts.dart';
import 'planthealth.dart';
import 'reports.dart';
import 'checklist.dart';
import 'scan.dart';
import 'services/api_service.dart';

class CODetectorDashboard extends StatefulWidget {
  const CODetectorDashboard({super.key});

  @override
  State<CODetectorDashboard> createState() => _CODetectorDashboardState();
}

class _CODetectorDashboardState extends State<CODetectorDashboard> {
  final api = CODetectorApiService();
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
      if (mounted) {
        setState(() {
          total = s["total_units"] ?? s["total"] ?? 0;
          active = s["active_units"] ?? s["active"] ?? 0;
          
          // Standardized health calculation
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
    return Scaffold(
      backgroundColor: const Color(0xFFFDE8E8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 25, 20, 15),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.1), blurRadius: 10)]),
                        child: const Icon(Icons.arrow_back_ios_new, size: 22, color: Colors.red),
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("CO Detector", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFB71C1C))),
                        Text("Emergency Response Unit", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFD32F2F), Color(0xFF424242)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("UNIT STATUS", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        SizedBox(height: 4),
                        Text("Emergency Readiness", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, height: 1.1)),
                        SizedBox(height: 6),
                        Text("Tracking unit location.", style: TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Image.asset('assets/co_detector.png', height: 95, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.medical_services, color: Colors.white, size: 70)),
                ],
              ),
              ),
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _metricTile("Active Units", isLoading ? "..." : "$active", Colors.green.shade700),
                    const SizedBox(width: 15),
                    _metricTile("Service Due", isLoading ? "..." : "${total - active}", Colors.red.shade800),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.15,
                children: [
                  _ActionCard("Plant Health", Icons.analytics_outlined, Colors.green, const CODetectorPlantHealthPage(), "Device Health"),
                  _ActionCard("Alerts", Icons.notification_important_outlined, Colors.red, const CODetectorAlertsPage(), "Safety Alerts"),
                  _ActionCard("Maintenance", Icons.build_circle_outlined, Colors.orange, const CODetectorMaintenancePage(), "Services"),
                  _ActionCard("Reports", Icons.summarize_outlined, Colors.purple, const CODetectorReportsPage(), "History"),
                  _ActionCard("Checklist", Icons.fact_check_outlined, Colors.teal, const CODetectorChecklistPage(), "Forms"),
                  _ActionCard("Inspection", Icons.camera_enhance_outlined, Colors.blue, const CODetectorScanPage(), "Scan"),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), border: Border.all(color: color.withOpacity(0.1)), boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
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
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFB71C1C), fontSize: 14)),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
