import 'package:flutter/material.dart';
import 'alerts.dart';
import 'checklist.dart';
import 'maintaince.dart';
import 'planthealth.dart';
import 'reports.dart';
import 'scan.dart';
import 'services/api_service.dart';

class CO2SystemDashboard extends StatefulWidget {
  const CO2SystemDashboard({super.key});
  @override
  State<CO2SystemDashboard> createState() => _CO2SystemDashboardState();
}

class _CO2SystemDashboardState extends State<CO2SystemDashboard> {
  final api = CO2SystemApiService();
  int total = 0, active = 0, health = 0;
  bool isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final s = await api.getSummary();
      if (mounted) {
        setState(() {
          total = s["total_units"] ?? s["total"] ?? 0;
          active = s["active_units"] ?? s["active"] ?? 0;
          final hs = s["health_score"];
          if (hs != null && hs > 0) health = hs.toInt();
          else if (total > 0) health = ((active / total) * 100).toInt();
          else health = 0;
          isLoading = false;
        });
      }
    } catch (_) { if (mounted) setState(() => isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF1976D2);
    const Color accent = Color(0xFFBBDEFB);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: primary.withOpacity(0.1), blurRadius: 10)]),
                  child: const Icon(Icons.arrow_back_ios_new, size: 18, color: primary),
                ),
              ),
              const SizedBox(width: 12),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("CO2System", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: primary)),
                Text("Emergency Response Unit", style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              ]),
              const Spacer(),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]), child: Row(children: [const Icon(Icons.favorite, color: Colors.red, size: 16), const SizedBox(width: 6), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("OVERALL HEALTH", style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.grey)), Text("$health%", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black))])])),
            ]),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [primary, Color(0xFF0D47A1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Row(children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("LIVE MONITORING", style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                SizedBox(height: 5),
                Text("Response Readiness", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, height: 1.1)),
                SizedBox(height: 5),
                Text("Tracking unit location & equipment.", style: TextStyle(color: Colors.white60, fontSize: 11)),
              ])),
              Image.asset("assets/co2_system.png", height: 60, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.medical_services, size: 50, color: Colors.white)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(children: [
              _metricTile("Active Units", isLoading ? "..." : "$active", Colors.green.shade700),
              const SizedBox(width: 12),
              _metricTile("Service Due", isLoading ? "..." : "${total - active}", primary),
            ]),
          ),
          Expanded(child: GridView.count(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.25,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _ActionCard("Plant Health", Icons.analytics_outlined, Colors.green, const CO2SystemPlantHealthPage(), "Device Health"),
              _ActionCard("Safety Alerts", Icons.notification_important_outlined, Colors.red, const CO2SystemAlertsPage(), "Active Alerts"),
              _ActionCard("Maintenance", Icons.build_circle_outlined, Colors.orange, const CO2SystemMaintenancePage(), "Services"),
              _ActionCard("Reports", Icons.summarize_outlined, Colors.purple, const CO2SystemReportsPage(), "History"),
              _ActionCard("Checklist", Icons.fact_check_outlined, Colors.teal, const CO2SystemChecklistPage(), "Forms"),
              _ActionCard("Inspection", Icons.qr_code_scanner, Colors.blue, const CO2SystemScanPage(), "Search"),
            ],
          )),
        ]),
      ),
    );
  }

  Widget _metricTile(String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
      ]),
    ));
  }
}

class _ActionCard extends StatelessWidget {
  final String title; final IconData icon; final Color color; final Widget page; final String subtitle;
  const _ActionCard(this.title, this.icon, this.color, this.page, this.subtitle);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 8)),
            const BoxShadow(color: Colors.white, blurRadius: 10, offset: Offset(-5, -5)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 22)),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0D47A1), fontSize: 12)),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 8, fontWeight: FontWeight.bold)),
          ]),
        ]),
      ),
    );
  }
}
