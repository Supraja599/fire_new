import 'package:flutter/material.dart';

class SCBAUnitsMaintenancePage extends StatelessWidget {
  const SCBAUnitsMaintenancePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(title: const Text("Maintenance Details"), backgroundColor: Colors.white, elevation: 1),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image.asset("assets/scba_unit.png", height: 120, opacity: const AlwaysStoppedAnimation(0.3), errorBuilder: (c,e,s) => Icon(Icons.air, size: 100, color: Colors.grey.shade300)),
        const SizedBox(height: 20),
        const Text("No maintenance records found", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        const Text("All units are up to date", style: TextStyle(color: Colors.grey, fontSize: 12)),
      ])),
    );
  }
}

