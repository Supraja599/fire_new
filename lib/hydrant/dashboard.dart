import 'dart:async';
import 'package:fire_new/services/apiservice.dart';
import 'package:flutter/material.dart';

import 'alerts.dart';
import 'checklist.dart';
import 'maintaince.dart';
import 'planthealth.dart';
import 'reports.dart';
import 'scan.dart';
import 'services/hydrant_api_service.dart';

class HydrantDashboardPage extends StatefulWidget {
  const HydrantDashboardPage({super.key});

  @override
  State<HydrantDashboardPage> createState() => _HydrantDashboardPageState();
}

class _HydrantDashboardPageState extends State<HydrantDashboardPage> {
  static const Color primary = Color(0xFFC62828);

  final HydrantApiService api = HydrantApiService();
  bool isLoading = true;
  int active = 0;
  int risk = 0;
  int total = 0, health = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      await api.syncModuleData();
      final s = await api.getSummary();
      if (mounted && s != null) {
        setState(() {
          active = s["active"] ?? 0;
          risk = (s["needs_service"] ?? 0) + (s["expired"] ?? 0);
          total = s["total"] ?? (active + risk);
          health = ApiService.calculateHealth(s);
          isLoading = false;
        });
      } else if (mounted) {
        setState(() => isLoading = false);
      }
    } catch (_) { if (mounted) setState(() => isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: primary), onPressed: () => Navigator.pop(context)),
                  const Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text("Fire Hydrant", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, color: Colors.red, size: 14),
                        const SizedBox(width: 4),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text("HEALTH", style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.grey)),
                          Text("$health%", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // HERO CARD
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFD84315), Color(0xFF8E1C1C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [BoxShadow(color: primary.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("LIVE READINESS", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            const SizedBox(height: 10),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(isLoading ? "Loading..." : "$active Active Hydrants", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.2)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                        child: const Icon(Icons.fire_hydrant_alt, color: Colors.white, size: 30),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _statusTag(isLoading ? "..." : "$active Active", Icons.check_circle, Colors.green),
                      _statusTag(isLoading ? "..." : "$risk At Risk", Icons.warning, Colors.orange),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // GRID
            LayoutBuilder(
              builder: (context, constraints) {
                final double width = MediaQuery.of(context).size.width;
                int crossAxisCount = 2;
                if (width > 900) crossAxisCount = 4;
                else if (width > 600) crossAxisCount = 3;

                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: width > 600 ? 1.1 : 1.0,
                  children: [
                    _buildBox(context, "Plant Health", Icons.health_and_safety_outlined, const HydrantPlantHealthPage(), Colors.green, "Unit Health"),
                    _buildBox(context, "Alerts", Icons.crisis_alert_outlined, const HydrantAlertsPage(), Colors.red, "Safety"),
                    _buildBox(context, "Maintenance", Icons.build_circle_outlined, const HydrantMaintenancePage(), Colors.orange, "Services"),
                    _buildBox(context, "Reports", Icons.receipt_long_outlined, const HydrantReportsPage(), Colors.purple, "History"),
                    _buildBox(context, "Checklist", Icons.checklist_rtl_outlined, const HydrantChecklistPage(), Colors.blue, "Forms"),
                    _buildBox(context, "Inspection", Icons.center_focus_strong_outlined, const HydrantScanPage(), Colors.teal, "Check"),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Flexible(child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildBox(BuildContext context, String title, IconData icon, Widget page, Color color, String sub) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
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
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(fit: BoxFit.scaleDown, child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0D47A1), fontSize: 14))),
                FittedBox(fit: BoxFit.scaleDown, child: Text(sub, style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
