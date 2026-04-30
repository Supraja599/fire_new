import 'dart:math';
import 'package:flutter/material.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  final List<Map<String, dynamic>> all = [];

  /// 🔴 GROUPED (DATE → ITEMS)
  Map<DateTime, List<Map<String, dynamic>>> grouped = {};

  @override
  void initState() {
    super.initState();
    generateData();
    processData();
  }

  /// 🔥 GENERATE DATA
  void generateData() {
    final random = Random();

    for (int i = 0; i < 500; i++) {
      int offset;

      if (i < 150) {
        offset = -random.nextInt(5) - 1; // past (missed)
      } else {
        offset = random.nextInt(5);
      }

      all.add({
        "id": "SPR-${1000 + i}",
        "location": "Zone-${random.nextInt(10) + 1}",
        "pressure": "${70 + random.nextInt(30)} PSI",
        "date": DateTime.now().add(Duration(days: offset)),
        "done": random.nextBool(),
      });
    }
  }

  /// 🔴 PROCESS + LIMIT PER DATE
  void processData() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    List<Map<String, dynamic>> missed = [];

    for (var item in all) {
      DateTime d = item["date"];
      bool done = item["done"];

      DateTime itemDate = DateTime(d.year, d.month, d.day);

      if (itemDate.isBefore(today) && !done) {
        missed.add(item);
      }
    }

    /// SORT (latest first → yesterday first)
    missed.sort((a, b) => b["date"].compareTo(a["date"]));

    /// GROUP + LIMIT (ONLY 2 PER DAY)
    for (var item in missed) {
      DateTime d = item["date"];
      DateTime key = DateTime(d.year, d.month, d.day);

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }

      /// LIMIT 2 ITEMS PER DATE ✅
      if (grouped[key]!.length < 2) {
        grouped[key]!.add(item);
      }
    }

    setState(() {});
  }

  /// 📅 LABEL
  String getLabel(DateTime d) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));

    if (d == yesterday) return "Yesterday";
    return "${d.day}/${d.month}";
  }

  @override
  Widget build(BuildContext context) {
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // latest first

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      /// 🔴 APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.notifications_active, color: Colors.red),
            SizedBox(width: 8),
            Text(
              "Alerts",
              style: TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(12),
        children: sortedKeys.map((dateKey) {
          final list = grouped[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// 🔴 DATE HEADER
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  getLabel(dateKey),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),

              /// 🔥 ITEMS (ONLY 2)
              ...list.map((item) {
                return GestureDetector(
                  onTap: () => showDetails(item),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.red.withValues(alpha: 0.25)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                        )
                      ],
                    ),
                    child: Row(
                      children: [

                        /// 💧 ICON
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.water_drop,
                              color: Colors.red),
                        ),

                        const SizedBox(width: 12),

                        /// TEXT
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item["id"],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text(item["location"],
                                  style: TextStyle(
                                      color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// 🔥 DETAILS POPUP
  void showDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Icon(Icons.water_drop,
                  size: 45, color: Colors.red),

              const SizedBox(height: 10),

              Text(
                item["id"],
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              _row("Location", item["location"]),
              _row("Pressure", item["pressure"]),
              _row("Status", "Inspection Missed ❌"),
              _row(
                "Date",
                "${item["date"].day}/${item["date"].month}/${item["date"].year}",
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String a, String b) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text("$a: ",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(b),
        ],
      ),
    );
  }
}