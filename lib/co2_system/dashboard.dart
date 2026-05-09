import 'package:flutter/material.dart';
import 'package:fire_new/services/apiservice.dart';
import 'maintaince.dart';
import 'alerts.dart';
import 'planthealth.dart';
import 'reports.dart';
import 'checklist.dart';
import 'scan.dart';

import 'services/api_service.dart';

class CO2SystemDashboard extends StatefulWidget {
  const CO2SystemDashboard({super.key});

  @override
  State<CO2SystemDashboard> createState() => _CO2SystemDashboardState();
}

class _CO2SystemDashboardState extends State<CO2SystemDashboard> {
  static const Color primary = Color(0xFF00838F);
  static const Color accent = Color(0xFFB2EBF2);
  static const Color textDark = Color(0xFF006064);

  final api = CO2SystemApiService();
  bool isLoading = true;
  int deviceCount = 0;
  int efficiency = 98; 

  int total = 0, health = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final s = await api.getSummary();
      if (mounted && s != null) {
        setState(() {
          total = s["total_units"] ?? s["total"] ?? 0;
          deviceCount = s["active_units"] ?? s["active"] ?? 0;
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
                        child: Text("CO2 System", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
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
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "Gas Suppression\nSystem",
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textDark, height: 1.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Image.asset(
                        'assets/co2_system.png',
                        height: 70,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const Icon(Icons.cloud, color: primary, size: 50),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _statusTag(isLoading ? "Loading..." : "$deviceCount Units Online", Icons.check_circle, Colors.green),
                      _statusTag(isLoading ? "..." : "$health% Safety", Icons.speed, primary),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // BIG ACTION CARDS (RESPONSIVE GRID)
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
                      _BigActionCard("Plant Health", Icons.analytics_outlined, const CO2SystemPlantHealthPage(), Colors.green.shade600, "Device Health"),
                      _BigActionCard("Safety Alerts", Icons.notification_important_outlined, const CO2SystemAlertsPage(), Colors.red.shade600, "Active Alerts"),
                      _BigActionCard("Maintenance", Icons.build_circle_outlined, const CO2SystemMaintenancePage(), Colors.orange.shade700, "Services"),
                      _BigActionCard("Reports", Icons.summarize_outlined, const CO2SystemReportsPage(), Colors.purple.shade600, "History"),
                      _BigActionCard("Checklist", Icons.fact_check_outlined, const CO2SystemChecklistPage(), Colors.teal.shade700, "Forms"),
                      _BigActionCard("Inspection", Icons.camera_enhance_outlined, const CO2SystemScanPage(), Colors.blue.shade700, "Scan"),
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
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 8)),
          ],
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF006064), fontSize: 14),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
