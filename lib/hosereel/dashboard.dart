import 'package:flutter/material.dart';

// Screens
import 'scan.dart';
import 'checklist.dart';
import 'reports.dart';
import 'maintaince.dart';
import 'alerts.dart';
import 'plant health.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<String> images = [
    "assets/hosereel.png",
    "assets/hosereel2.png",
    "assets/hosereel3.png",
    "assets/hosereel4.png",
    "assets/hosereel5.png",

  ];

  // ================= NAVIGATION INDEX =================
  static const int dashboardIndex = 0;
  static const int scanIndex = 1;
  static const int checklistIndex = 2;
  static const int maintenanceIndex = 3;
  static const int alertsIndex = 4;
  static const int plantHealthIndex = 5;
  static const int reportsIndex = 6;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1000);
    _autoScroll();
  }

  void _autoScroll() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _navigateTo(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _goHomeFromScan() {
    setState(() {
      _currentIndex = 0;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildDashboard(),

            ScanScreen(onBackToHome: _goHomeFromScan),
            ChecklistPage(),
            const MaintenanceScreen(),
            const HoseReelAlertsPage(),
            const PlantHealthScreen(),
            const ReportsPage(),
          ],
        ),
      ),
    );
  }

  // ================= DASHBOARD =================
  Widget _buildDashboard() {
    return Column(
      children: [

        Align(
          alignment: Alignment.topLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.redAccent),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: _pageController,
            itemBuilder: (context, index) {
              final image = images[index % images.length];
              return _buildImageCard(image);
            },
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          "Fire Hose Reel Assets",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),

        const SizedBox(height: 20),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [

                    _bigIcon(
                      icon: Icons.qr_code_scanner_rounded,
                      label: "Scan",
                      color: Colors.redAccent,
                      onTap: () => _navigateTo(scanIndex),
                    ),

                    _bigIcon(
                      icon: Icons.fact_check_rounded,
                      label: "Checklist",
                      color: Colors.green,
                      onTap: () => _navigateTo(checklistIndex),
                    ),

                    _bigIcon(
                      icon: Icons.build_circle_rounded,
                      label: "Maintenance",
                      color: Colors.deepPurple,
                      onTap: () => _navigateTo(maintenanceIndex),
                    ),
                  ],
                ),

                const SizedBox(height: 35),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [

                    _bigIcon(
                      icon: Icons.warning_amber_rounded,
                      label: "Alerts",
                      color: Colors.orange,
                      onTap: () => _navigateTo(alertsIndex),
                    ),

                    _bigIcon(
                      icon: Icons.local_florist_rounded,
                      label: "Plant Health",
                      color: Colors.teal,
                      onTap: () => _navigateTo(plantHealthIndex),
                    ),

                    _bigIcon(
                      icon: Icons.analytics_rounded,
                      label: "Reports",
                      color: Colors.blue,
                      onTap: () => _navigateTo(reportsIndex),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= IMAGE CARD =================
  Widget _buildImageCard(String path) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Container(
            color: Colors.white,
            child: Image.asset(path, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  // ================= ICON =================
  Widget _bigIcon({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [

          Container(
            height: 85,
            width: 85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.25),
                  color.withOpacity(0.10),
                ],
              ),
            ),
            child: Icon(icon, size: 40, color: color),
          ),

          const SizedBox(height: 10),

          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}