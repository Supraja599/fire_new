import 'package:flutter/material.dart';

class FireTrolleyMaintenancePage extends StatelessWidget {
  const FireTrolleyMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Fire Trolley Maintenance", style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: 4,
        itemBuilder: (context, index) {
          final color = index == 2 ? Colors.orange : Colors.blue;
          final status = index == 2 ? "Wheel Service" : "Equipment Check";
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                  child: Container(
                    width: 96,
                    height: 108,
                    color: color.withOpacity(0.08),
                    child: Image.asset(
                      'assets/fire_trolley.webp',
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => Icon(Icons.shopping_cart, color: color, size: 40),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("TROLLEY-0${index + 1}", style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        const Text("Emergency Response Point A"),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _chip(status, color),
                            _chip("Next 10/07/2026", Colors.grey.shade700),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
