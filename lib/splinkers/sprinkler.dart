import 'dart:async';
import 'package:flutter/material.dart';
import 'planthealth.dart';
import 'checklist.dart';
import 'maintaince.dart';
import 'alerts.dart';
import 'reports.dart';
import 'scan.dart';

class SprinklerPage extends StatefulWidget {
  const SprinklerPage({super.key});

  @override
  State<SprinklerPage> createState() => _SprinklerPageState();
}

class _SprinklerPageState extends State<SprinklerPage> {
  static const Color primaryRed = Color(0xFFD32F2F);

  final PageController _pageController = PageController();
  int currentPage = 0;

  final List<String> images = [
    'assets/s1.png',
    'assets/s2.png',
    'assets/s3.png',
    // ✅ FIXED (comma added)
    'assets/s5.png',
  ];

  Timer? timer;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 4), (t) {
      currentPage = (currentPage + 1) % images.length;

      _pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );

      setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      /// 🔻 BOTTOM NAV
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: primaryRed,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔴 HEADER TITLE
            /// 🔴 HEADER TITLE + BACK BUTTON
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: primaryRed,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Text(
                    "Fire Sprinkler Dashboard",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryRed,
                    ),
                  ),
                ],
              ),
            ),

            /// 🖼️ IMAGE SLIDER
            Container(
              height: 300,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 90,
                  ),
                ],
              ),
              child: PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Center(
                    child: Image.asset(
                      images[index],
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),

            /// 🔘 DOT INDICATORS
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(images.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: currentPage == index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: currentPage == index
                          ? primaryRed
                          : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),
            ),

            /// 🔥 GAP
            const SizedBox(height: 50),

            /// 🔲 GRID SECTION
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                  children: [
                    _card(
                      Icons.favorite,
                      "Plant Health",
                      Colors.green,
                      const PlantHealthPage(),
                    ),

                    _card(
                      Icons.build,
                      "Maintenance",
                      Colors.orange,
                      const MaintenancePage(),
                    ),

                    _card(
                      Icons.checklist,
                      "Checklist",
                      Colors.blue,
                      const ChecklistPage(),
                    ),

                    _card(
                      Icons.description,
                      "Reports",
                      Colors.purple,
                      const ReportsPage(),
                    ),

                    _card(
                      Icons.notifications,
                      "Alerts",
                      Colors.red,
                      const AlertsPage(),
                    ),

                    _card(
                      Icons.qr_code_scanner,
                      "Scan",
                      Colors.teal,
                      const ScanPage(),
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

  /// 🔲 CARD UI
  Widget _card(IconData icon, String title, Color color, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// 🔥 ICON
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: color),
            ),

            const SizedBox(height: 10),

            /// TEXT
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// SETTINGS PAGE
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Settings Page")));
  }
}
