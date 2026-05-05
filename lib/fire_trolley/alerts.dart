import 'package:flutter/material.dart';

class FireTrolleyAlertsPage extends StatelessWidget {
  const FireTrolleyAlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Fire Trolley Alerts", style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 1,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Missing Fire Blanket", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text("Trolley: TROLLEY-02", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                const Text("Critical", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }
}
