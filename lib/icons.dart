import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dashboard.dart';
import 'hydrant/dashboard.dart';
import 'hosereel/dashboard.dart' as hose;
import 'splinkers/sprinkler.dart';
import 'alarm_panel/dashboard.dart';
import 'smoke_detector/dashboard.dart';
import 'fire_trolley/dashboard.dart';
import 'emergency_exits/dashboard.dart';
import 'emergency_lighting/dashboard.dart';
import 'pa_system/dashboard.dart';
import 'wind_sock/dashboard.dart';
import 'scba_units/dashboard.dart';
import 'ambulance/dashboard.dart';
import 'first_aid/dashboard.dart';
import 'emergency_shower/dashboard.dart';
import 'eye_wash/dashboard.dart';
import 'spill_kits/dashboard.dart';
import 'chemical_shower/dashboard.dart';
import 'ppe_cabinets/dashboard.dart';
import 'co2_system/dashboard.dart';
import 'signage/dashboard.dart';
import 'emergency_comm/dashboard.dart';
import 'fire_blankets/dashboard.dart';
import 'muster_points/dashboard.dart';

// API services for each module
import 'services/apiservice.dart';

// Generic module detail page for lookup by equipment ID
import 'icons/module_detail_page.dart';

class IconsPage extends StatefulWidget {
  const IconsPage({super.key});

  @override
  State<IconsPage> createState() => _IconsPageState();
}

class Item {
  final String icon;
  final String name;
  final int value;
  final String status;
  final String detail;
  final Widget? page;

  Item(this.icon, this.name, this.value, this.status, this.detail, this.page);
}

class _IconsPageState extends State<IconsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool isDark = true;

  final List<Item> items = [
    Item('🧯', 'Fire extinguishers', 95, 'green', 'All OK', const DashboardPage()),
    Item('🧵', 'Hose reels', 98, 'green', 'OK', const hose.Dashboard()),
    Item('🚿', 'Sprinkler system', 100, 'green', 'OK', const SprinklerPage()),
    Item('🚒', 'Hydrant points', 100, 'green', 'OK', const HydrantDashboardPage()),
    Item('🔔', 'Fire alarm panels', 100, 'green', 'OK', const AlarmPanelDashboard()),
    Item('🌫️', 'Smoke detectors', 95, 'amber', 'OK', const SmokeDetectorDashboard()),
    Item('🛒', 'Fire trolley', 100, 'green', 'OK', const FireTrolleyDashboard()),
    Item('🚪', 'Emergency exits', 100, 'green', 'OK', const EmergencyExitsDashboard()),
    Item('💡', 'Emergency lighting', 97, 'green', 'OK', const EmergencyLightingDashboard()),
    Item('📢', 'PA system', 100, 'green', 'OK', const PASystemDashboard()),
    Item('📡', 'Wind sock', 100, 'green', 'OK', const WindSockDashboard()),
    Item('🫁', 'SCBA units', 66, 'amber', 'Check', const SCBAUnitsDashboard()),
    Item('🚑', 'Ambulance', 50, 'red', 'Needs attention', const AmbulanceDashboard()),
    Item('🏥', 'First aid', 93, 'green', 'OK', const FirstAidDashboard()),
    Item('🚰', 'Emergency shower', 100, 'green', 'OK', const EmergencyShowerDashboard()),
    Item('👀', 'Eye wash', 87, 'green', 'Check', const EyeWashDashboard()),
    Item('⚗️', 'Spill kits', 90, 'green', 'OK', const SpillKitsDashboard()),
    Item('🛁', 'Chemical shower', 100, 'green', 'OK', const ChemicalShowerDashboard()),
    Item('🥾', 'PPE cabinets', 91, 'green', 'OK', const PPECabinetsDashboard()),
    Item('☁️', 'CO2 system', 100, 'green', 'OK', const CO2SystemDashboard()),
    Item('⚠️', 'Signage', 96, 'green', 'OK', const SignageDashboard()),
    Item('📞', 'Emergency comm.', 80, 'amber', 'Check', const EmergencyCommDashboard()),
    Item('🧲', 'Fire blankets', 100, 'green', 'OK', const FireBlanketsDashboard()),
    Item('📍', 'Muster points', 100, 'green', 'OK', const MusterPointsDashboard()),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color getColor(String status) {
    switch (status) {
      case 'green':
        return Colors.green;
      case 'amber':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  double get overallHealth {
    final total = items.fold<double>(0, (sum, item) => sum + item.value);
    return total / items.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  const Text("Safety Ecosystem", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
                  const Spacer(),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white70 : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "System Status",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 15,
                          children: [
                            _legend(Colors.green, "Active"),
                            _legend(Colors.orange, "Service"),
                            _legend(Colors.red, "Critical"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Switch(
                        value: isDark,
                        activeColor: Colors.blue,
                        onChanged: (value) {
                          setState(() {
                            isDark = value;
                          });
                        },
                      ),
                      SizedBox(
                        height: 80,
                        width: 90,
                        child: CustomPaint(
                          painter: GaugePainter(overallHealth),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 1,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isRed = item.status == 'red';

                    return GestureDetector(
                      onTap: () {
                        if (item.page != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => item.page!),
                          );
                        }
                      },
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          final opacity =
                              isRed ? (_controller.value * 0.6 + 0.4) : 1.0;
                          return Opacity(opacity: opacity, child: child);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: getColor(item.status).withOpacity(0.2),
                            border: Border.all(color: getColor(item.status)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(item.icon, style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: 4),
                              Text(
                                item.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

class GaugePainter extends CustomPainter {
  final double value;

  GaugePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    paint.color = Colors.red;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi / 3,
      false,
      paint,
    );

    paint.color = Colors.orange;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi + math.pi / 3,
      math.pi / 3,
      false,
      paint,
    );

    paint.color = Colors.green;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi + 2 * (math.pi / 3),
      math.pi / 3,
      false,
      paint,
    );

    final angle = math.pi + (value / 100) * math.pi;

    final needlePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 6;

    final needleEnd = Offset(
      center.dx + radius * 0.8 * math.cos(angle),
      center.dy + radius * 0.8 * math.sin(angle),
    );

    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 7, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
