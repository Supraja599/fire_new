import 'package:flutter/material.dart';
import 'package:fire_new/hosereel/services/apiservice.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final api = HoseReelApiService();

  List<dynamic> allList = [];
  List<dynamic> todayList = [];
  List<dynamic> tomorrowList = [];
  List<dynamic> displayList = [];

  String selectedFilter = "all";
  int totalCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  DateTime? parseDate(String? date) {
    if (date == null || date.isEmpty) return null;
    try {
      return DateTime.parse(date);
    } catch (_) {
      return null;
    }
  }

  bool isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool isTomorrow(DateTime d) {
    final t = DateTime.now().add(const Duration(days: 1));
    return d.year == t.year && d.month == t.month && d.day == t.day;
  }

  Future<void> loadData() async {
    try {
      final data = await api.getByStatus("due-inspection");

      List<dynamic> tdy = [];
      List<dynamic> tmr = [];

      for (var item in data) {
        final date = parseDate(
          item["next_inspection_date"] ?? item["scheduled_date"],
        );

        if (date != null) {
          if (isToday(date)) tdy.add(item);
          if (isTomorrow(date)) tmr.add(item);
        }
      }

      setState(() {
        allList = data;
        todayList = tdy;
        tomorrowList = tmr;
        displayList = data;
        totalCount = data.length;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void applyFilter(String type) {
    setState(() {
      selectedFilter = type;

      if (type == "today") {
        displayList = todayList;
      } else if (type == "tomorrow") {
        displayList = tomorrowList;
      } else {
        displayList = allList;
      }
    });
  }

  String getValue(Map item, List<String> keys) {
    for (var key in keys) {
      if (item[key] != null && item[key].toString().isNotEmpty) {
        return item[key].toString();
      }
    }
    return "Zone A";
  }

  void openDetails(Map item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Maintenance"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5E35B1), Color(0xFF7E57C2)],
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// TOTAL CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                ),
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
              child: Text(
                "Total Upcoming: $totalCount",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// FILTER
            Row(
              children: [
                _box("Today", todayList.length, Colors.green, "today"),
                const SizedBox(width: 10),
                _box("Tomorrow", tomorrowList.length, Colors.orange, "tomorrow"),
                const SizedBox(width: 10),
                _box("All", allList.length, Colors.blue, "all"),
              ],
            ),

            const SizedBox(height: 16),

            /// LIST
            Expanded(
              child: displayList.isEmpty
                  ? const Center(child: Text("No Data"))
                  : ListView.builder(
                itemCount: displayList.length,
                itemBuilder: (_, i) {
                  final item = displayList[i];

                  final id = getValue(item, ["sos_id", "id"]);
                  final location = getValue(item, ["location", "zone", "building"]);
                  final date = getValue(item, ["next_inspection_date", "scheduled_date"]);

                  return GestureDetector(
                    onTap: () => openDetails(item),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.white, Color(0xFFF1F4F9)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 55,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                              ),
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                          ),
                          const SizedBox(width: 12),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("ID: $id",
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(location),
                              ],
                            ),
                          ),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Icon(Icons.arrow_forward_ios,
                                  size: 14, color: Colors.grey),
                              const SizedBox(height: 6),
                              Text(date,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _box(String title, int count, Color color, String type) {
    final selected = selectedFilter == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => applyFilter(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: selected
                  ? [color, color.withOpacity(0.7)]
                  : [color.withOpacity(0.3), color.withOpacity(0.5)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(title, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 5),
              Text(
                "$count",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🔥 FULL DETAILS SCREEN (INSIDE SAME FILE)
class DetailScreen extends StatelessWidget {
  final Map item;

  const DetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF141E30), Color(0xFF243B55)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              /// HEADER
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Details",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ),

              /// BODY
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: ListView(
                    children: item.entries.map((e) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF7F8FA), Colors.white],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${e.key} : ${e.value ?? "N/A"}",
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}