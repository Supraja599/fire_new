import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fire_new/services/apiservice.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  List<Map<String, dynamic>> activeList = [];
  List<Map<String, dynamic>> serviceList = [];
  List<Map<String, dynamic>> inspectionList = [];
  List<Map<String, dynamic>> expiredList = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);

    final res = await Future.wait([
      ApiService.getActive(),
      ApiService.getNeedsService(),
      ApiService.getDueInspection(),
      ApiService.getExpired(),
    ]);

    setState(() {
      activeList = res[0];
      serviceList = res[1];
      inspectionList = res[2];
      expiredList = res[3];
      isLoading = false;
    });
  }

  // ================= COLORS =================
  final activeColor = const Color(0xFF2E7D32);
  final serviceColor = const Color(0xFFFF8F00);
  final inspectionColor = const Color(0xFF1565C0);
  final expiredColor = const Color(0xFFC62828);

  // ================= PIE DATA =================
  List<PieChartSectionData> getSections() {
    final data = [
      {"label": "Active", "value": activeList.length, "color": activeColor},
      {"label": "Need Service", "value": serviceList.length, "color": serviceColor},
      {"label": "Due Inspection", "value": inspectionList.length, "color": inspectionColor},
      {"label": "Expired", "value": expiredList.length, "color": expiredColor},
    ];

    return List.generate(data.length, (i) {
      final value = data[i]["value"] as int;
      final label = data[i]["label"] as String;

      return PieChartSectionData(
        value: value.toDouble(),
        color: data[i]["color"] as Color,
        radius: 70,

        // 🔥 NAME + VALUE INSIDE SLICE
        title: "$label\n$value",

        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),

        titlePositionPercentageOffset: 0.55,
      );
    });
  }

  // ================= ICONS =================
  IconData getIcon(String type) {
    switch (type) {
      case "Active":
        return Icons.check_circle;
      case "Need Service":
        return Icons.handyman;
      case "Due Inspection":
        return Icons.fact_check;
      case "Expired":
        return Icons.warning;
      default:
        return Icons.circle;
    }
  }

  Color getColor(String type) {
    switch (type) {
      case "Active":
        return activeColor;
      case "Need Service":
        return serviceColor;
      case "Due Inspection":
        return inspectionColor;
      case "Expired":
        return expiredColor;
      default:
        return Colors.grey;
    }
  }

  // ================= TOTAL COUNT =================
  Widget totalCard() {
    int total = activeList.length +
        serviceList.length +
        inspectionList.length +
        expiredList.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "TOTAL FIRE EXTINGUISHERS",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            "$total",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // ================= DETAILS POPUP =================
  void showDetailsPopup(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 40),
                const SizedBox(height: 14),
                const Text(
                  "Equipment Details",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                ...item.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: Text(entry.value?.toString() ?? "-"),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= LIST PAGE =================
  void openIdList(String title, List<Map<String, dynamic>> list) {
    final color = getColor(title);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFFF4F6F9),
          appBar: AppBar(
            title: Text("$title Extinguishers"),
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black),
            titleTextStyle: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          body: list.isEmpty
              ? const Center(child: Text("No items found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final sosId = item["sos_code"] ?? item["serial_number"] ?? item["id"] ?? "-";

                    return GestureDetector(
                      onTap: () => showDetailsPopup(item),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                              child: Container(
                                width: 90,
                                height: 100,
                                color: color.withOpacity(0.08),
                                child: Image.asset(
                                  'assets/extinguisher.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Icon(Icons.fire_extinguisher, color: color, size: 30),
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
                                      "SOS ID: $sosId",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item["location_name"] ?? "Unknown Location",
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  // ================= BUTTON CARD =================
  Widget buildCard(String title, int count, List<Map<String, dynamic>> list) {
    final color = getColor(title);
    final icon = getIcon(title);

    return Expanded(
      child: GestureDetector(
        onTap: () => openIdList(title, list),
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.95),
                color.withOpacity(0.65),
              ],
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "$count",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text(
          "FIRE EXTINGUISHER HEALTH",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              const SizedBox(height: 20),

              // ================= PIE WITH CENTER =================
              SizedBox(
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: getSections(),
                        centerSpaceRadius: 60,
                      ),
                    ),

                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.local_fire_department,
                          color: Colors.red,
                          size: 28,
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Fire\nExtinguishers",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ================= TOTAL =================
              totalCard(),

              const SizedBox(height: 25),

              // ================= BUTTONS =================
              Row(
                children: [
                  buildCard("Active", activeList.length, activeList),
                  buildCard("Need Service", serviceList.length, serviceList),
                ],
              ),

              Row(
                children: [
                  buildCard("Due Inspection", inspectionList.length, inspectionList),
                  buildCard("Expired", expiredList.length, expiredList),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}