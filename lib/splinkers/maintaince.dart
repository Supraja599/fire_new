import 'dart:math';
import 'package:flutter/material.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  final List<Map<String, dynamic>> all = [];

  List<Map<String, dynamic>> today = [];
  List<Map<String, dynamic>> tomorrow = [];
  List<Map<String, dynamic>> next3Days = [];
  List<Map<String, dynamic>> later = [];

  String selected = "Today";

  @override
  void initState() {
    super.initState();
    generateData();
    splitData();
  }

  /// 🔥 500 DUMMY DATA
  void generateData() {
    final random = Random();

    for (int i = 0; i < 500; i++) {
      int offset;

      if (i < 180) {
        offset = 0;
      } else if (i < 300) {
        offset = 1;
      } else if (i < 420) {
        offset = random.nextInt(3) + 2;
      } else {
        offset = random.nextInt(20) + 5;
      }

      all.add({
        "id": "SPR-${1000 + i}",
        "location": "Zone-${random.nextInt(12) + 1}",
        "pressure": "${70 + random.nextInt(30)} PSI",
        "date": DateTime.now().add(Duration(days: offset)),
      });
    }
  }

  void splitData() {
    DateTime now = DateTime.now();

    for (var item in all) {
      int diff = item["date"].difference(now).inDays;

      if (diff == 0) {
        today.add(item);
      } else if (diff == 1) {
        tomorrow.add(item);
      } else if (diff <= 3) {
        next3Days.add(item);
      } else {
        later.add(item);
      }
    }

    setState(() {});
  }

  List<Map<String, dynamic>> getSelectedList() {
    switch (selected) {
      case "Today":
        return today;
      case "Tomorrow":
        return tomorrow;
      case "Next 3 Days":
        return next3Days;
      default:
        return later;
    }
  }

  Color getColor(String type) {
    switch (type) {
      case "Today":
        return Colors.red;
      case "Tomorrow":
        return Colors.orange;
      case "Next 3 Days":
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getColor(selected);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        title: const Text("Maintenance Schedule"),
        backgroundColor: Colors.white,
        elevation: 2,
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [

            /// 🔴 FIXED TABS
            Row(
              children: [
                _tab("Today"),
                _tab("Tomorrow"),
                _tab("Next 3 Days"),
                _tab("Later"),
              ],
            ),

            const SizedBox(height: 12),

            /// LIST
            Expanded(
              child: ListView.builder(
                itemCount: getSelectedList().take(15).length,
                itemBuilder: (context, index) {
                  final item = getSelectedList()[index];

                  return GestureDetector(
                    onTap: () => showDetails(item),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: Row(
                        children: [

                          /// 💧 SPRINKLER ICON
                          Icon(
                            Icons.water_drop,
                            color: color,
                            size: 30,
                          ),

                          const SizedBox(width: 10),

                          /// INFO
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item["id"],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  item["location"],
                                  style: TextStyle(
                                      color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),

                          /// DATE
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${item["date"].day}/${item["date"].month}",
                              style: TextStyle(color: color),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔘 TAB
  Widget _tab(String title) {
    final isSelected = selected == title;
    final color = getColor(title);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selected = title),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 📄 DETAILS (BIG SPRINKLER ICON TOP)
  void showDetails(Map<String, dynamic> item) {
    Color color = getColor(selected);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              /// 🔥 BIG SPRINKLER ICON
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.water_drop,
                  size: 65,
                  color: color,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                item["id"],
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              _row("Location", item["location"], color),
              _row("Pressure", item["pressure"], color),
              _row(
                "Date",
                "${item["date"].day}/${item["date"].month}/${item["date"].year}",
                color,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String a, String b, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$a: ",
            style: TextStyle(fontWeight: FontWeight.bold, color: c),
          ),
          Text(b),
        ],
      ),
    );
  }
}