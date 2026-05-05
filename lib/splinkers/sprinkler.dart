import 'dart:async';
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

  final PageController _pageController = PageController();
  int currentPage = 0;
  bool isLoading = true;

  final List<String> images = [
    'assets/sprinkler.png',
  ];

  Timer? timer;

  @override
  void initState() {
    super.initState();
    _initData();
    timer = Timer.periodic(const Duration(seconds: 4), (t) {
      if (images.length > 1) {
        currentPage = (currentPage + 1) % images.length;
        _pageController.animateToPage(
          currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        setState(() {});
      }
    });
  }

  Future<void> _initData() async {
    try {
      await api.syncModuleData();
    } catch (_) {}
    if (mounted) setState(() => isLoading = false);
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
                  const Text(
                    "Sprinkler Dashboard",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryRed,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 220,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
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
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const Icon(Icons.water_drop, size: 80, color: primaryRed),
                    ),
                  );
                },
              ),
            ),
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
            const SizedBox(height: 30),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                  children: [
                    _card(
                      Icons.health_and_safety,
                      "Plant Health",
                      Colors.green,
                      const SprinklerPlantHealthPage(),
                    ),
                    _card(
                      Icons.settings_suggest,
                      "Maintenance",
                      Colors.orange,
                      const SprinklerMaintenancePage(),
                    ),
                    _card(
                      Icons.fact_check,
                      "Checklist",
                      Colors.blue,
                      const SprinklerChecklistPage(),
                    ),
                    _card(
                      Icons.assignment,
                      "Reports",
                      Colors.purple,
                      const SprinklerReportsPage(),
                    ),
                    _card(
                      Icons.crisis_alert,
                      "Alerts",
                      Colors.red,
                      const SprinklerAlertsPage(),
                    ),
                    _card(
                      Icons.qr_code_scanner,
                      "Scan",
                      Colors.teal,
                      const SprinklerScanPage(),
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

  Widget _card(IconData icon, String title, Color color, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
