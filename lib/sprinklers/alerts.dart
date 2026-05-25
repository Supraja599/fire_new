import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';

class SprinklerAlertsPage extends StatefulWidget {
  const SprinklerAlertsPage({super.key});

  @override
  State<SprinklerAlertsPage> createState() => _SprinklerAlertsPageState();
}

class _SprinklerAlertsPageState extends State<SprinklerAlertsPage> {
  final api = ModuleApiService.sprinkler;
  final List<Map<String, dynamic>> all = [];

  Map<DateTime, List<Map<String, dynamic>>> grouped = {};
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
      grouped = {};

      for (final item in equipment) {
        final status = item["status_bucket"]?.toString() ?? "";
        final dueDate = parseDate(item["next_inspection_due"]?.toString());
        final expiryDate = parseDate(item["expiry_date"]?.toString());
        final alertDate = status == "expired" ? expiryDate : dueDate;

        if (!["due-inspection", "needs-service", "expired"].contains(status) ||
            alertDate == null) {
          continue;
        }

        all.add({
          "id":
              item["sos_code"] ?? item["serial_number"] ?? item["id"] ?? "N/A",
          "location": item["location_name"] ?? item["zone_name"] ?? "Unknown",
          "pressure":
              "${item["details"]?["operating_pressure_bar"] ?? "N/A"} bar",
          "system_type": item["details"]?["system_type"] ?? "N/A",
          "status": status,
          "date": alertDate,
        });
      }

      processData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void processData() {
    final sorted = [
      ...all,
    ]..sort((a, b) => (b["date"] as DateTime).compareTo(a["date"] as DateTime));

    for (final item in sorted) {
      final d = item["date"] as DateTime;
      final key = DateTime(d.year, d.month, d.day);
      grouped.putIfAbsent(key, () => []).add(item);
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  String getLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (d == yesterday) return "Yesterday";
    return "${d.day}/${d.month}";
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Alerts")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              "Unable to load sprinkler alerts.\n$error",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
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
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: sortedKeys.isEmpty
          ? const Center(child: Text("No sprinkler alerts found"))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: sortedKeys.map((dateKey) {
                final list = grouped[dateKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              color: Colors.red.withOpacity(0.25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Image.asset(
                                  'assets/sprinkler.png',
                                  width: 45,
                                  height: 45,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.water_drop,
                                    color: Colors.red,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "SOS ID: ${item["id"]}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item["location"],
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
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

  void showDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/sprinkler.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.water_drop, size: 40, color: Colors.red),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                "SOS ID: ${item["id"]}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _row("Location", item["location"]),
              _row("Pressure", item["pressure"]),
              _row("System", item["system_type"]),
              _row("Status", item["status"].toString().toUpperCase()),
              _row(
                "Alert Date",
                "${item["date"].day}/${item["date"].month}/${item["date"].year}",
              ),
              const SizedBox(height: 20),
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
          Text("$a: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(b)),
        ],
      ),
    );
  }
}
