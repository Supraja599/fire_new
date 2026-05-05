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
                      "Hydrant Command Center",
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

            // 🖼️ REAL IMAGE & STATS CARD
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
                    color: primary.withOpacity(0.18),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "LIVE READINESS",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isLoading ? "Loading..." : "$active Active Hydrants",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          shape: BoxShape.circle,
                          image: const DecorationImage(
                            image: AssetImage('assets/firehydrant.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: const Icon(
                          Icons.fire_hydrant_alt,
                          size: 30,
                          color: Colors.white24, // Subtle fallback
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  
                  // 📊 SIMPLE TREND GRAPH (Premium Custom UI)
                  SizedBox(
                    height: 80,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: TrendGraphPainter(
                        points: [0.2, 0.5, 0.4, 0.8, 0.7, 0.9, 0.8],
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 14),
            
            // METRICS
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

            // ICON GRID
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
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
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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

// ✅ TREND GRAPH PAINTER
class TrendGraphPainter extends CustomPainter {
  final List<double> points;
  final Color color;

  TrendGraphPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final step = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * step;
      final y = size.height - (points[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
    
    // Gradient under line
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
      
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.2), Colors.transparent],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));
      
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
              color: Colors.black.withOpacity(0.06),
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
                color: color.withOpacity(0.12),
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
