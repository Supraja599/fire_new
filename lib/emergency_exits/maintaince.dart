import 'package:flutter/material.dart';

class EmergencyExitsMaintenancePage extends StatelessWidget {
  const EmergencyExitsMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(title: const Text("Maintenance Details"), backgroundColor: Colors.white, elevation: 1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/emergency_exit.png", height: 120, opacity: const AlwaysStoppedAnimation(0.3)),
            const SizedBox(height: 20),
            const Text("No maintenance records found", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text("All units are up to date", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
