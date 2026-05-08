import 'package:flutter/material.dart';
import 'package:fire_new/services/apiservice.dart';
import 'alerts.dart';
import 'checklist.dart';
import 'maintaince.dart';
import 'planthealth.dart';
import 'reports.dart';
import 'scan.dart';
import 'services/api_service.dart';

class EmergencyExitsDashboard extends StatefulWidget {
  const EmergencyExitsDashboard({super.key});
  @override
  State<EmergencyExitsDashboard> createState() => _EmergencyExitsDashboardState();
}

class _EmergencyExitsDashboardState extends State<EmergencyExitsDashboard> {
  static const Color primary = Color(0xFF1976D2);
  static const Color accent = Color(0xFFBBDEFB);
  final api = EmergencyExitsApiService();
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
          
          // Logic for Health Score
          health = ApiService.calculateHealth(s);
          
          isLoading = false;
        });
      }
    } catch (_) { if (mounted) setState(() => isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          Padding(padding: const EdgeInsets.all(20), child: Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back, color: primary), onPressed: () => Navigator.pop(context)),
            const Spacer(),
            const Text("Emergency Exits", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]), child: Row(children: [const Icon(Icons.favorite, color: Colors.red, size: 16), const SizedBox(width: 6), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("OVERALL HEALTH", style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.grey)), Text("$health%", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black))])])),
          ])),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(40)),
            child: Column(children: [
              Row(children: [
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Live Monitoring", style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(height: 5),
                  Text("Exit System", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1), height: 1.1)),
                ])),
                Image.asset("assets/emergency_exit.png", height: 80, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.door_front_door, size: 70, color: primary)),
              ]),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _tag(isLoading ? "..." : "$active Active", Icons.check_circle, Colors.green),
                _tag(isLoading ? "..." : "$health% Health", Icons.favorite, Colors.red),
              ]),
            ]),
          ),
          const SizedBox(height: 30),
          Expanded(child: GridView.count(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            crossAxisCount: 2, crossAxisSpacing: 20, mainAxisSpacing: 20, childAspectRatio: 1.1,
            children: [
              _Card("Plant Health", Icons.analytics_outlined, const EmergencyExitsPlantHealthPage(), Colors.green.shade600, "Device Health"),
              _Card("Safety Alerts", Icons.notification_important_outlined, const EmergencyExitsAlertsPage(), Colors.red.shade600, "Active Alerts"),
              _Card("Maintenance", Icons.build_circle_outlined, const EmergencyExitsMaintenancePage(), Colors.orange.shade700, "Services"),
              _Card("Reports", Icons.summarize_outlined, const EmergencyExitsReportsPage(), Colors.purple.shade600, "History"),
              _Card("Checklist", Icons.fact_check_outlined, const EmergencyExitsChecklistPage(), Colors.teal.shade700, "Forms"),
              _Card("Inspection", Icons.qr_code_scanner, const EmergencyExitsScanPage(), Colors.blue.shade700, "Search"),
            ],
          )),
        ]),
      ),
    );
  }

  Widget _tag(String t, IconData i, Color c) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: Row(children: [Icon(i, size: 16, color: c), const SizedBox(width: 8), Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: c))]));

  Widget _Card(String t, IconData i, Widget p, Color c, String s) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => p)),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: c.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: Icon(i, color: c, size: 32)),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0D47A1), fontSize: 14)), Text(s, style: TextStyle(color: Colors.grey.shade500, fontSize: 10))]),
      ]),
    ),
  );
}

