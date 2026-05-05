import 'package:flutter/material.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: const Color(0xFFD50000), title: const Text("Alarm Panel Analytics", style: TextStyle(color: Colors.white)), iconTheme: const IconThemeData(color: Colors.white)),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text("System Uptime: 99.9%", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("False Alarms (Last 30 days): 2", style: TextStyle(fontSize: 16)),
            // Add charts later
          ],
        ),
      ),
    );
  }
}
