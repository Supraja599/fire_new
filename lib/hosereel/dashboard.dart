import 'dart:async';

import 'package:flutter/material.dart';

import 'alerts.dart';
import 'checklist.dart';
import 'maintaince.dart';
import 'plant health.dart';
import 'reports.dart';
import 'scan.dart';
import 'services/apiservice.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  static const Color primaryRed = Color(0xFFD32F2F);

  final HoseReelApiService api = HoseReelApiService();
  final PageController _pageController = PageController();

  final List<String> images = [
    'assets/hosereel.png',
    'assets/hosereel2.png',
    'assets/hosereel3.png',
    'assets/hosereel4.png',
    'assets/hosereel5.png',
  ];

  Timer? timer;
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    unawaited(api.syncModuleData());

    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      currentPage = (currentPage + 1) % images.length;

      _pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );

      if (mounted) {
        setState(() {});
      }
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
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: primaryRed,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _SettingsPage()),
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
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Fire Hose Reel Dashboard",
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
            const SizedBox(height: 50),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                  children: const [
                    _DashboardCard(
                      icon: Icons.favorite,
                      title: "Plant Health",
                      color: Colors.green,
                      page: PlantHealthScreen(),
                    ),
                    _DashboardCard(
                      icon: Icons.build,
                      title: "Maintenance",
                      color: Colors.orange,
                      page: MaintenanceScreen(),
                    ),
                    _DashboardCard(
                      icon: Icons.checklist,
                      title: "Checklist",
                      color: Colors.blue,
                      page: ChecklistPage(),
                    ),
                    _DashboardCard(
                      icon: Icons.description,
                      title: "Reports",
                      color: Colors.purple,
                      page: ReportsPage(),
                    ),
                    _DashboardCard(
                      icon: Icons.notifications,
                      title: "Alerts",
                      color: Colors.red,
                      page: HoseReelAlertsPage(),
                    ),
                    _DashboardCard(
                      icon: Icons.qr_code_scanner,
                      title: "Scan",
                      color: Colors.teal,
                      page: ScanScreen(),
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
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget page;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
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
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 10),
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

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Settings Page")));
  }
}
