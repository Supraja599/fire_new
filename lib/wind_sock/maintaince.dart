import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';

class WindSockMaintenancePage extends StatefulWidget {
  const WindSockMaintenancePage({super.key});

  @override
  State<WindSockMaintenancePage> createState() => _WindSockMaintenancePageState();
}

class _WindSockMaintenancePageState extends State<WindSockMaintenancePage> {
  final api = ModuleApiService.windSock;
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
    _loadData();
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadData() async {
    try {
      final equipment = await api.getEquipmentList();

      all.clear();
      today = [];
      tomorrow = [];
      next3Days = [];
      later = [];

      for (final item in equipment) {
        final date = _parseDate(item["next_inspection_due"]?.toString());
        if (date == null) continue;

        final status = item["status_bucket"]?.toString().toLowerCase() ?? "active";
        if (status == "expired") continue; // 🔥 EXPIRED ITEMS SHOULD GO TO ALERTS

        all.add({
          "id":
              item["sos_code"] ?? item["serial_number"] ?? item["id"] ?? "N/A",
          "location": item["location_name"] ?? item["zone_name"] ?? "Unknown",
          "status": status,
          "brand":
              item["brand"]?.toString() ?? "N/A",
          "model":
              item["model"]?.toString() ?? "N/A",
          "date": date,
        });
      }

      _splitData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _splitData() {
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

  List<Map<String, dynamic>> _selectedList() {
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

  Color _colorFor(String type) {
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
    final color = _colorFor(selected);

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
              "Unable to load wind sock maintenance schedule.\n$error",
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
              child: _selectedList().isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              'assets/wind_sock.webp',
                              width: 100,
                              height: 100,
                              fit: BoxFit.contain,
                              opacity: const AlwaysStoppedAnimation(0.5),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "No Maintenance for $selected",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Everything is up to date!",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _selectedList().length,
                      itemBuilder: (context, index) {
                        final item = _selectedList()[index];

                        return GestureDetector(
                          onTap: () => _showDetails(item),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(20),
                                  ),
                                  child: Container(
                                    width: 96,
                                    height: 108,
                                    color: color.withOpacity(0.08),
                                    child: Image.asset(
                                      'assets/wind_sock.webp',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item["id"],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item["location"],
                                          style: TextStyle(color: Colors.grey.shade600),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            _chip(item["brand"] != "N/A" ? item["brand"] : "Standard", color),
                                            _chip(item["model"] != "N/A" ? item["model"] : "Unit", Colors.grey.shade700),
                                            _chip("${item["date"].day}/${item["date"].month}", color),
                                          ],
                                        ),
                                      ],
                                    ),
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
    final color = _colorFor(title);

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

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> item) {
    final color = _colorFor(selected);

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
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/wind_sock.webp',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                item["id"],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              _row("Location", item["location"], color),
              _row("Brand", item["brand"], color),
              _row("Model", item["model"], color),
              _row("Status", item["status"], color),
              _row(
                "Next Inspection",
                "${item["date"].day}/${item["date"].month}/${item["date"].year}",
                color,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
