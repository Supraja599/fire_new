import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔢 SAMPLE DATA (like plant 500)
    final int total = 500;
    final int critical = 25;
    final int warning = 60;
    final int normal = 415;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          "Fire Hose Reel Alerts",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🔥 SUMMARY CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8)
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("System Alerts",
                          style: TextStyle(color: Colors.white70)),
                      SizedBox(height: 6),
                      Text("Fire Hose Reel Status",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text(
                    "$total",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔴 STATUS CARDS
            Row(
              children: [
                _statusCard("Critical", critical, Colors.red),
                const SizedBox(width: 10),
                _statusCard("Warning", warning, Colors.orange),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _statusCard("Normal", normal, Colors.green),
                const SizedBox(width: 10),
                _statusCard("Inactive", 0, Colors.grey),
              ],
            ),

            const SizedBox(height: 20),

            /// 🔥 CRITICAL ALERT LIST TITLE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Critical Alerts",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Icon(Icons.warning, color: Colors.red),
              ],
            ),

            const SizedBox(height: 10),

            /// 🔥 ALERT LIST
            Expanded(
              child: ListView(
                children: [
                  _alertTile(
                    "Hose Reel #102",
                    "Pressure Drop Detected",
                    "2 min ago",
                    Colors.red,
                  ),
                  _alertTile(
                    "Hose Reel #87",
                    "Valve Leakage",
                    "10 min ago",
                    Colors.red,
                  ),
                  _alertTile(
                    "Hose Reel #56",
                    "Inspection Overdue",
                    "1 hour ago",
                    Colors.orange,
                  ),
                  _alertTile(
                    "Hose Reel #210",
                    "Low Water Flow",
                    "2 hours ago",
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔷 STATUS CARD
  Widget _statusCard(String title, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.7), color],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 ALERT TILE
  Widget _alertTile(
      String title, String subtitle, String time, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 5)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4)
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: color),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                    const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),

          Text(time,
              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }
}