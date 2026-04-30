import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'hosereel/dashboard.dart' as hose;
import 'dart:math' as math;
import 'splinkers/sprinkler.dart';
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

  /// ✅ THEME SWITCH (ADDED)
  bool isDark = true;

  final List<Item> items = [
    Item('🧯','Fire extinguishers',95,'green','All OK', const DashboardPage()),
    Item('🧵','Hose reels',98,'green','OK', const hose.Dashboard()),
    Item('🚿','Sprinkler system',100,'green','OK', const SprinklerPage()),
    Item('🚒','Hydrant points',100,'green','OK', null),
    Item('🔔','Fire alarm panels',100,'green','OK', null),
    Item('🌫️','Smoke detectors',95,'amber','OK', null),
    Item('🛒','Fire trolley',100,'green','OK', null),
    Item('🚪','Emergency exits',100,'green','OK', null),
    Item('💡','Emergency lighting',97,'green','OK', null),
    Item('📢','PA system',100,'green','OK', null),
    Item('📡','Wind sock',100,'green','OK', null),
    Item('🫁','SCBA units',66,'amber','Check', null),
    Item('🚑','Ambulance',50,'red','Needs attention', null),
    Item('🏥','First aid',93,'green','OK', null),
    Item('🚰','Emergency shower',100,'green','OK', null),
    Item('👀','Eye wash',87,'green','Check', null),
    Item('⚗️','Spill kits',90,'green','OK', null),
    Item('🛁','Chemical shower',100,'green','OK', null),
    Item('🦺','PPE cabinets',91,'green','OK', null),
    Item('☁️','CO2 system',100,'green','OK', null),
    Item('⚠️','Signage',96,'green','OK', null),
    Item('📞','Emergency comm.',80,'amber','Check', null),
    Item('🧲','Fire blankets',100,'green','OK', null),
    Item('📍','Muster points',100,'green','OK', null),
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
    double total = items.fold(0, (sum, item) => sum + item.value);
    return total / items.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// ✅ BACKGROUND CHANGE
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,

      body: SafeArea(
        child: Column(
          children: [

            /// 🔥 HEADER
            Container(
              height: MediaQuery.of(context).size.height * 0.24,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                /// ✅ HEADER COLOR CHANGE
                color: isDark ? Colors.white70 : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),

              /// ✅ ROW UPDATED (FOR SWITCH)
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  /// LEFT SIDE
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Plant Health",
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${overallHealth.toStringAsFixed(0)}%",
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        Wrap(
                          spacing: 20,
                          children: [
                            _legend(Colors.green, "Active"),
                            _legend(Colors.orange, "Service"),
                            _legend(Colors.red, "Critical"),
                          ],
                        )
                      ],
                    ),
                  ),

                  /// RIGHT SIDE (GAUGE + SWITCH)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      /// 🔥 SWITCH (ADDED)
                      Switch(
                        value: isDark,
                        onChanged: (value) {
                          setState(() {
                            isDark = value;
                          });
                        },
                      ),

                      /// GAUGE
                      SizedBox(
                        height: 100,
                        width: 110,
                        child: CustomPaint(
                          painter: GaugePainter(overallHealth),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),

            /// 🔥 GRID
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    childAspectRatio: 1,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    bool isRed = item.status == 'red';

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
                          double opacity =
                          isRed ? (_controller.value * 0.6 + 0.4) : 1.0;

                          return Opacity(opacity: opacity, child: child);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: getColor(item.status)
                                .withValues(alpha: 0.2),
                            border: Border.all(
                                color: getColor(item.status)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(item.icon,
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(height: 4),
                              Text(
                                item.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                /// ✅ TEXT COLOR FIX
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

/// 🔥 GAUGE (UNCHANGED)
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
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        math.pi, math.pi / 3, false, paint);

    paint.color = Colors.orange;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        math.pi + math.pi / 3, math.pi / 3, false, paint);

    paint.color = Colors.green;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        math.pi + 2 * (math.pi / 3), math.pi / 3, false, paint);

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