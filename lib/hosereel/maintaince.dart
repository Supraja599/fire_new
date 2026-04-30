import 'package:flutter/material.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      /// ❌ NO TITLE BAR TEXT
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🔥 TOTAL UPCOMING (TOP MAIN CARD)
            _totalCard(),

            const SizedBox(height: 20),

            /// 🔥 TODAY & TOMORROW
            Row(
              children: [
                _topCard(
                  title: "Today",
                  count: "2 Tasks",
                  icon: Icons.bolt_rounded, // ⚡ better icon
                  color: Colors.green,
                ),
                const SizedBox(width: 10),
                _topCard(
                  title: "Tomorrow",
                  count: "3 Tasks",
                  icon: Icons.calendar_today_rounded, // 📅 better
                  color: Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// 📋 HEADER
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Upcoming Schedule",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// 📋 LIST
            Expanded(
              child: ListView(
                children: const [

                  /// 🔥 TODAY
                  _maintenanceTile(
                    title: "Fire Pump Routine Check",
                    date: "Today",
                    location: "Utility Area",
                    color: Colors.green,
                  ),

                  /// 🔥 TOMORROW
                  _maintenanceTile(
                    title: "Fire Hose Reel Inspection",
                    date: "Tomorrow",
                    location: "Block A",
                    color: Colors.orange,
                  ),

                  /// 🔷 OTHER DATES
                  _maintenanceTile(
                    title: "Hydrant Pressure Test",
                    date: "25 Sep",
                    location: "Plant 2",
                    color: Colors.blue,
                  ),
                  _maintenanceTile(
                    title: "Sprinkler System Check",
                    date: "28 Sep",
                    location: "Warehouse",
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 TOTAL CARD (TOP DASHBOARD STYLE)
  static Widget _totalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF673AB7), Color(0xFF512DA8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard_customize_rounded,
                  color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text(
                "Total Upcoming",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Text(
            "12 Tasks",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔥 TODAY / TOMORROW CARDS
  static Widget _topCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 6),
            Text(title,
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(
              count,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 📋 MAINTENANCE TILE
class _maintenanceTile extends StatelessWidget {
  final String title;
  final String date;
  final String location;
  final Color color;

  const _maintenanceTile({
    required this.title,
    required this.date,
    required this.location,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6)
        ],
      ),
      child: Row(
        children: [

          /// 🔵 LEFT STATUS BAR
          Container(
            width: 6,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),

          const SizedBox(width: 12),

          /// TEXT CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Location: $location",
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text("Date: $date",
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),

          /// DATE BADGE
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              date,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}