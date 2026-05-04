import 'dart:async';

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
  static const Color deep = Color(0xFF7F1010);
  static const List<String> gallery = [
    'assets/firehydrant.png',
    'assets/firehydrant.png',
    'assets/firehydrant.png',
  ];

  final HydrantApiService api = HydrantApiService();
  final PageController _pageController = PageController();
  Timer? _timer;
  int currentPage = 0;
  bool isLoading = true;
  int active = 0;
  int risk = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      currentPage = (currentPage + 1) % gallery.length;
      _pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadSummary() async {
    await api.syncModuleData();
    final summary = await api.getSummary();
    if (!mounted) return;
    setState(() {
      active = summary["active"] ?? 0;
      risk = (summary["needs_service"] ?? 0) + (summary["expired"] ?? 0);
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EE),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    color: primary,
                  ),
                  const Expanded(
                    child: Text(
                      "Hydrant Point Command Deck",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: deep,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD84315), Color(0xFF8E1C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.18),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
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
                              "Live Hydrant Readiness",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Pressure, access, and response screens in one place.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.fire_hydrant_alt,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 210,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: gallery.length,
                        itemBuilder: (context, index) {
                          return Container(
                            color: Colors.white,
                            child: Image.asset(gallery[index], fit: BoxFit.contain),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(gallery.length, (index) {
                      final selected = currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: selected ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : Colors.white54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  _miniMetric(
                    "Active",
                    isLoading ? "..." : active.toString(),
                    const Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 10),
                  _miniMetric(
                    "Risk",
                    isLoading ? "..." : risk.toString(),
                    const Color(0xFFC62828),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
                  children: const [
                    _HydrantCard(
                      title: "Plant Health",
                      icon: Icons.monitor_heart_outlined,
                      color: Color(0xFF2E7D32),
                      page: HydrantPlantHealthPage(),
                    ),
                    _HydrantCard(
                      title: "Maintenance",
                      icon: Icons.build_circle_outlined,
                      color: Color(0xFFEF6C00),
                      page: HydrantMaintenancePage(),
                    ),
                    _HydrantCard(
                      title: "Checklist",
                      icon: Icons.fact_check_outlined,
                      color: Color(0xFF1565C0),
                      page: HydrantChecklistPage(),
                    ),
                    _HydrantCard(
                      title: "Reports",
                      icon: Icons.insert_chart_outlined,
                      color: Color(0xFF6A1B9A),
                      page: HydrantReportsPage(),
                    ),
                    _HydrantCard(
                      title: "Alerts",
                      icon: Icons.notifications_active_outlined,
                      color: Color(0xFFC62828),
                      page: HydrantAlertsPage(),
                    ),
                    _HydrantCard(
                      title: "Scan",
                      icon: Icons.qr_code_scanner_rounded,
                      color: Color(0xFF00897B),
                      page: HydrantScanPage(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniMetric(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HydrantCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget page;

  const _HydrantCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
