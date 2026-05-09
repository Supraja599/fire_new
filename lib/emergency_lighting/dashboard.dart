import 'package:flutter/material.dart';
import 'package:fire_new/services/apiservice.dart';
import 'alerts.dart';
import 'checklist.dart';
import 'maintaince.dart';
import 'planthealth.dart';
import 'reports.dart';
import 'scan.dart';
import 'services/api_service.dart';

class EmergencyLightingDashboard extends StatefulWidget {
  const EmergencyLightingDashboard({super.key});
  @override
  State<EmergencyLightingDashboard> createState() => _EmergencyLightingDashboardState();
}

class _EmergencyLightingDashboardState extends State<EmergencyLightingDashboard> {
  static const Color primary = Color(0xFF1976D2);
  static const Color accent = Color(0xFFBBDEFB);
  final api = EmergencyLightingApiService();
  int total = 0, active = 0, health = 0;
  bool isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
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
            Padding(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20), child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: primary), onPressed: () => Navigator.pop(context)),
              const Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text("Emergency Lighting", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  ),
                ),
              ),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]), child: Row(children: [const Icon(Icons.favorite, color: Colors.red, size: 14), const SizedBox(width: 4), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("HEALTH", style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.grey)), Text("$health%", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black))])])),
            ])),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(40)),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("Live Monitoring", style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 5),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text("Emergency Lighting System", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1), height: 1.1)),
                    ),
                  ])),
                  const SizedBox(width: 10),
                  Image.asset("assets/emergency_lighting.png", height: 70, fit: BoxFit.contain, errorBuilder: (c,e,s) => Icon(Icons.lightbulb, size: 50, color: primary)),
                ]),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _tag(isLoading ? "..." : "$active Active", Icons.check_circle, Colors.green),
                    _tag(isLoading ? "..." : "$health% Health", Icons.favorite, Colors.red),
                  ],
                ),
              ]),
            ),
            const SizedBox(height: 20),
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
                    _Card("Plant Health", Icons.analytics_outlined, const EmergencyLightingPlantHealthPage(), Colors.green.shade600, "Device Health"),
                    _Card("Safety Alerts", Icons.notification_important_outlined, const EmergencyLightingAlertsPage(), Colors.red.shade600, "Active Alerts"),
                    _Card("Maintenance", Icons.build_circle_outlined, const EmergencyLightingMaintenancePage(), Colors.orange.shade700, "Services"),
                    _Card("Reports", Icons.summarize_outlined, const EmergencyLightingReportsPage(), Colors.purple.shade600, "History"),
                    _Card("Checklist", Icons.fact_check_outlined, const EmergencyLightingChecklistPage(), Colors.teal.shade700, "Forms"),
                    _Card("Inspection", Icons.qr_code_scanner, const EmergencyLightingScanPage(), Colors.blue.shade700, "Search"),
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

  Widget _tag(String t, IconData i, Color c) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(i, size: 16, color: c), const SizedBox(width: 8), Flexible(child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: c), overflow: TextOverflow.ellipsis))]));

  Widget _Card(String t, IconData i, Widget p, Color c, String s) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => p)),
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: c.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(i, color: c, size: 28)),
        const SizedBox(height: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FittedBox(fit: BoxFit.scaleDown, child: Text(t, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0D47A1), fontSize: 14))),
          const SizedBox(height: 2),
          FittedBox(fit: BoxFit.scaleDown, child: Text(s, style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold))),
        ]),
      ]),
    ),
  );
}
