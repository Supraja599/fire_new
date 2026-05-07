import 'package:flutter/material.dart';
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
  int efficiency = 98; // Default fallback

  int total = 0, health = 0;

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
          deviceCount = s["active_units"] ?? s["active"] ?? 0;
          final hs = s["health_score"];
          if (hs != null && hs > 0)
            health = hs.toInt();
          else if (total > 0)
            health = ((deviceCount / total) * 100).toInt();
          else
            health = 0;
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: primary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Text(
                    "CO2 System",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.red, size: 16),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "OVERALL HEALTH",
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "$health%",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
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
                              style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "Gas Suppression\nSystem",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: textDark,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Image.asset(
                        'assets/co2_system.png',
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) =>
                            const Icon(Icons.cloud, color: primary, size: 60),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statusTag(
                        isLoading
                            ? "Loading..."
                            : "$deviceCount Devices Online",
                        Icons.check_circle,
                        Colors.green,
                      ),
                      _statusTag(
                        isLoading ? "..." : "$efficiency% Efficiency",
                        Icons.speed,
                        primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // BIG ACTION CARDS (2x3 GRID)
            Expanded(
              child: GridView.count(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.1,
                children: [
                  _BigActionCard(
                    "Plant Health",
                    Icons.analytics_outlined,
                    const CO2SystemPlantHealthPage(),
                    Colors.green.shade600,
                    "Device Health",
                  ),
                  _BigActionCard(
                    "Safety Alerts",
                    Icons.notification_important_outlined,
                    const CO2SystemAlertsPage(),
                    Colors.red.shade600,
                    "Active Alerts",
                  ),
                  _BigActionCard(
                    "Maintenance",
                    Icons.build_circle_outlined,
                    const CO2SystemMaintenancePage(),
                    Colors.orange.shade700,
                    "Services",
                  ),
                  _BigActionCard(
                    "Reports",
                    Icons.summarize_outlined,
                    const CO2SystemReportsPage(),
                    Colors.purple.shade600,
                    "History",
                  ),
                  _BigActionCard(
                    "Checklist",
                    Icons.fact_check_outlined,
                    const CO2SystemChecklistPage(),
                    Colors.teal.shade700,
                    "Forms",
                  ),
                  _BigActionCard(
                    "Inspection",
                    Icons.camera_enhance_outlined,
                    const CO2SystemScanPage(),
                    Colors.blue.shade700,
                    "Scan",
                  ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 4)],
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
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

  const _BigActionCard(
    this.title,
    this.icon,
    this.page,
    this.color,
    this.subtitle,
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            const BoxShadow(
              color: Colors.white,
              blurRadius: 10,
              offset: const Offset(-5, -5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0D47A1),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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
