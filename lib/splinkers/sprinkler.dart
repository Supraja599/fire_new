import 'package:flutter/material.dart';
import 'planthealth.dart';
import 'checklist.dart';
import 'maintaince.dart';
import 'alerts.dart';
import 'reports.dart';
import 'scan.dart';
import 'services/sprinkler_api_service.dart';

class SprinklerPage extends StatefulWidget {
  const SprinklerPage({super.key});

  @override
  State<SprinklerPage> createState() => _SprinklerPageState();
}

class _SprinklerPageState extends State<SprinklerPage> {
  static const Color primaryRed = Color(0xFFD32F2F);
  final api = SprinklerApiService();
  int total = 0, active = 0, health = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await api.syncModuleData();
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back, color: primaryRed), onPressed: () => Navigator.pop(context)),
                  const Spacer(),
                  const Text("Sprinkler", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
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
                gradient: const LinearGradient(colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: primaryRed.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Row(
                children: [
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("SYSTEM STATUS", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    SizedBox(height: 8),
                    Text("Water Suppression", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, height: 1.2)),
                    SizedBox(height: 8),
                    Text("Monitoring pressure and valve readiness.", style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ])),
                  Image.asset("assets/sprinkler.png", height: 70, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.water_drop, size: 60, color: Colors.white)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.2,
                children: [
                  _buildCard("Plant Health", Icons.health_and_safety, Colors.green, const SprinklerPlantHealthPage()),
                  _buildCard("Maintenance", Icons.build, Colors.orange, const SprinklerMaintenancePage()),
                  _buildCard("Checklist", Icons.fact_check, Colors.blue, const SprinklerChecklistPage()),
                  _buildCard("Reports", Icons.description, Colors.purple, const SprinklerReportsPage()),
                  _buildCard("Alerts", Icons.warning, Colors.red, const SprinklerAlertsPage()),
                  _buildCard("Scan", Icons.search, Colors.teal, const SprinklerScanPage()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, Color color, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
