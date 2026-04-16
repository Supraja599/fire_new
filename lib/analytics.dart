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

  int touchedIndex = -1; // 👈 for click interaction

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

  // ================= PIE =================
  List<PieChartSectionData> getSections() {
    final data = [
      {"value": activeList.length, "color": Colors.green},
      {"value": serviceList.length, "color": Colors.orange},
      {"value": inspectionList.length, "color": Colors.blue},
      {"value": expiredList.length, "color": Colors.red},
    ];

    return List.generate(data.length, (i) {
      final isTouched = i == touchedIndex;

      return PieChartSectionData(
        value: (data[i]["value"] as int).toDouble(),
        color: data[i]["color"] as Color,
        radius: isTouched ? 90 : 80, // 👈 highlight effect
        title: (data[i]["value"] == 0)
            ? ""
            : "${data[i]["value"]}",
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  // ================= POPUP =================
  void showDetailsPopup(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("ID: ${item["id"]}"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              children: item.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(e.key.toString())),
                      Expanded(
                        child: Text(
                          e.value.toString(),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          )
        ],
      ),
    );
  }

  // ================= FULL PAGE =================
  void openFullPage(String title, List<Map<String, dynamic>> list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const Icon(Icons.qr_code),
                  title: Text("ID: ${item["id"]}"),
                  subtitle: Text(item["equipment_code"] ?? ""),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => showDetailsPopup(item),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ================= CARD =================
  Widget buildCard(String title, int count, Color color, List list) {
    return Expanded(
      child: GestureDetector(
        onTap: () => openFullPage(title, list.cast<Map<String, dynamic>>()),
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: color.withOpacity(0.08),
            border: Border.all(color: color),
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "$count",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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
    int total = activeList.length +
        serviceList.length +
        inspectionList.length +
        expiredList.length;

    // 👇 center text logic
    String centerTitle = "Total";
    int centerValue = total;

    if (touchedIndex == 0) {
      centerTitle = "Active";
      centerValue = activeList.length;
    } else if (touchedIndex == 1) {
      centerTitle = "Needs Service";
      centerValue = serviceList.length;
    } else if (touchedIndex == 2) {
      centerTitle = "Inspection";
      centerValue = inspectionList.length;
    } else if (touchedIndex == 3) {
      centerTitle = "Expired";
      centerValue = expiredList.length;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pie Chart",
          style: TextStyle(color: Colors.red),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: fetchData,
          )
        ],
      ),
      backgroundColor: Colors.grey.shade100,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 60),

          // PIE
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sections: getSections(),
                    centerSpaceRadius: 50,
                    sectionsSpace: 2,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = response
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                  ),
                ),
              ),

              // CENTER BOX
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 6,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(centerTitle,
                        style: const TextStyle(fontSize: 12)),
                    Text(
                      "$centerValue",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 80),

          // CARDS
          Row(
            children: [
              buildCard("Active", activeList.length,
                  Colors.green, activeList),
              buildCard("Needs Service", serviceList.length,
                  Colors.orange, serviceList),
            ],
          ),
          Row(
            children: [
              buildCard("Due Inspection", inspectionList.length,
                  Colors.blue, inspectionList),
              buildCard("Expired", expiredList.length,
                  Colors.red, expiredList),
            ],
          ),
        ],
      ),
    );
  }
}