import 'package:flutter/material.dart';

import 'services/sprinkler_api_service.dart';

class SprinklerMaintenancePage extends StatefulWidget {
  const SprinklerMaintenancePage({super.key});

  @override
  State<SprinklerMaintenancePage> createState() => _SprinklerMaintenancePageState();
}

class _SprinklerMaintenancePageState extends State<SprinklerMaintenancePage> {
  final api = SprinklerApiService();
  final List<Map<String, dynamic>> all = [];

  List<Map<String, dynamic>> today = [];
  List<Map<String, dynamic>> tomorrow = [];
  List<Map<String, dynamic>> next3Days = [];
  List<Map<String, dynamic>> later = [];

  String selected = "Today";
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  DateTime? parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }

  Future<void> loadData() async {
    try {
      final equipment = await api.getEquipmentList();

      all.clear();
      today = [];
      tomorrow = [];
      next3Days = [];
      later = [];

      for (final item in equipment) {
        final date = parseDate(item["next_inspection_due"]?.toString());
        if (date == null) continue;

        final status = item["status_bucket"]?.toString().toLowerCase() ?? "active";
        if (status == "expired") continue; // 🔥 EXPIRED ITEMS SHOULD GO TO ALERTS

        all.add({
          "id":
              item["sos_code"] ?? item["serial_number"] ?? item["id"] ?? "N/A",
          "location": item["location_name"] ?? item["zone_name"] ?? "Unknown",
          "pressure":
              "${item["details"]?["operating_pressure_bar"] ?? "N/A"} bar",
          "system_type": item["details"]?["system_type"] ?? "N/A",
          "heads": item["details"]?["sprinkler_count"]?.toString() ?? "N/A",
          "date": date,
        });
      }

      splitData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void splitData() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    for (final item in all) {
      final itemDate = item["date"] as DateTime;
      final itemStart = DateTime(itemDate.year, itemDate.month, itemDate.day);
      final diff = itemStart.difference(todayStart).inDays;

      if (diff == 0) {
        today.add(item);
      } else if (diff == 1) {
        tomorrow.add(item);
      } else if (diff >= 2 && diff <= 3) {
        next3Days.add(item);
      } else if (diff > 3) {
        later.add(item);
      }
    }

    if (!mounted) return;
    setState(() => isLoading = false);
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

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Maintenance Schedule")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "Unable to load sprinkler maintenance schedule.\n$error",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

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
            Row(
              children: [
                _tab("Today"),
                _tab("Tomorrow"),
                _tab("Next 3 Days"),
                _tab("Later"),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: getSelectedList().length,
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
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 60,
                              height: 60,
                              color: color.withValues(alpha: 0.1),
                              child: Image.asset(
                                'assets/sprinkler.png',
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) =>
                                    Icon(Icons.water_drop, color: color, size: 30),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item["id"],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  item["location"],
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
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

  void showDetails(Map<String, dynamic> item) {
    final color = getColor(selected);

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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                ),
                child: Image.asset(
                  'assets/sprinkler.png',
                  height: 65,
                  errorBuilder: (c, e, s) => Icon(Icons.water_drop, size: 65, color: color),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item["id"],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              _row("Location", item["location"], color),
              _row("Pressure", item["pressure"], color),
              _row("System", item["system_type"], color),
              _row("Heads", item["heads"], color),
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
          Expanded(child: Text(b)),
        ],
      ),
    );
  }
}
