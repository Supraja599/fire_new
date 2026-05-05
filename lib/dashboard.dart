import 'package:flutter/material.dart';
import 'inspection.dart';
import 'analytics.dart';
import 'maintenance.dart';
import 'alerts.dart';
import 'planthealth.dart';
import 'reports.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const Color primaryRed = Color(0xFFD50000); // ✅ TRUE RED

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    int crossAxisCount = 2;
    if (screenWidth > 900) {
      crossAxisCount = 4;
    } else if (screenWidth > 600) {
      crossAxisCount = 3;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [

                /// 🔴 HEADER (ONLY COLOR CHANGED)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: const BoxDecoration(
                    color: primaryRed,
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(80),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        "Extinguisher",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Company: Eltrive",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                /// BODY
                Expanded(
                  child: Column(
                    children: [

                      const SizedBox(height: 20),

                      const Text(
                        "What would you like to do?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        height: 3,
                        width: 50,
                        color: primaryRed,
                      ),

                      const SizedBox(height: 20),

                      /// GRID
                      Expanded(
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: screenWidth > 600 ? 1.2 : 1.0,
                          ),
                          itemCount: 6,
                          itemBuilder: (context, index) {
                            final items = [
                              ["Analytics", Icons.query_stats],
                              ["Inspection", Icons.assignment_turned_in],
                              ["Maintenance", Icons.handyman],
                              ["Alerts", Icons.notification_important],
                              ["Plant Health", Icons.health_and_safety],
                              ["Reports", Icons.assessment],
                            ];

                            return buildBox(
                              items[index][1] as IconData,
                              items[index][0] as String,
                                  () {
                                if (index == 0) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const AnalyticsPage()),
                                  );
                                } else if (index == 1) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const InspectionPage()),
                                  );
                                } else if (index == 2) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const MaintenancePage()),
                                  );
                                } else if (index == 3) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const AlertsPage()),
                                  );
                                } else if (index == 4) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const PlantHealthPage()),
                                  );
                                } else if (index == 5) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                        const ReportsPage()),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),

                      /// BOTTOM TEXT
                      const Padding(
                        padding: EdgeInsets.only(bottom: 20, top: 10),
                        child: Text(
                          "Inspection Streak: 0 months",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔴 BOX (ONLY COLOR UPDATED)
  Widget buildBox(
      IconData icon,
      String title,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: primaryRed,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryRed.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Icon(icon, color: Colors.white, size: 64),

            const SizedBox(height: 10),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}