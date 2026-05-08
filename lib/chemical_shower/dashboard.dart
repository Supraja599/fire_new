import 'package:flutter/material.dart';
import 'package:fire_new/services/apiservice.dart';
import 'maintaince.dart';
import 'alerts.dart';
import 'planthealth.dart';
import 'reports.dart';
import 'checklist.dart';
import 'scan.dart';

import 'services/api_service.dart';

class ChemicalShowerDashboard extends StatefulWidget {
  const ChemicalShowerDashboard({super.key});

  @override
  State<ChemicalShowerDashboard> createState() => _ChemicalShowerDashboardState();
}

class _ChemicalShowerDashboardState extends State<ChemicalShowerDashboard> {
  static const Color primary = Color(0xFF1976D2); // Using blue theme for Chemical Shower
  static const Color deep = Color(0xFF0D47A1);

  final api = ChemicalShowerApiService();
  bool isLoading = true;
  int activeUnits = 0;
  int openFaults = 0;
  int total = 0, health = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await api.syncModuleData();
      final s = await api.getSummary();
      if (mounted) {
        setState(() {
          activeUnits = s["active_units"] ?? s["active"] ?? 0;
          total = s["total_units"] ?? s["total"] ?? (activeUnits + (s["needs_service"] ?? 0) + (s["expired"] ?? 0));
          health = ApiService.calculateHealth(s);
          openFaults = (s["needs_service"] ?? 0) + (s["expired"] ?? 0);
          isLoading = false;
        });
      }
    } catch (_) { if (mounted) setState(() => isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Light blue-ish background
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: primary), onPressed: () => Navigator.pop(context)),
                  const Spacer(),
                  const Text("Chemical Shower", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
                    child: Row(children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 16),
                      const SizedBox(width: 6),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text("OVERALL HEALTH", style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text("$health%", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black)),
                      ]),
                    ]),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [primary, deep], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("SYSTEM OVERVIEW", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        SizedBox(height: 10),
                        Text("Response Readiness", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.2)),
                        SizedBox(height: 12),
                        Text("Central control for all chemical shower units.", style: TextStyle(color: Colors.white60, fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Image.asset('assets/chemical_shower.png', height: 110, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.medical_services, color: Colors.white, size: 80)),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _metricTile("Units Active", isLoading ? "..." : activeUnits.toString().padLeft(2, '0'), Colors.green.shade700),
                  const SizedBox(width: 15),
                  _metricTile("System Faults", isLoading ? "..." : openFaults.toString().padLeft(2, '0'), Colors.red.shade800),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.85,
                children: [
                  _ActionCard("Plant Health", Icons.health_and_safety_outlined, Colors.green, const ChemicalShowerPlantHealthPage()),
                  _ActionCard("Alerts", Icons.crisis_alert_outlined, Colors.red, const ChemicalShowerAlertsPage()),
                  _ActionCard("Maintenance", Icons.settings_suggest_outlined, Colors.orange, const ChemicalShowerMaintenancePage()),
                  _ActionCard("Reports", Icons.receipt_long_outlined, Colors.purple, const ChemicalShowerReportsPage()),
                  _ActionCard("Checklist", Icons.checklist_rtl_outlined, Colors.blue, const ChemicalShowerChecklistPage()),
                  _ActionCard("Inspection", Icons.center_focus_strong_outlined, Colors.teal, const ChemicalShowerScanPage()),
                ],
              ),
            ),
          ],
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

  const _ActionCard(this.title, this.icon, this.color, this.page);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

