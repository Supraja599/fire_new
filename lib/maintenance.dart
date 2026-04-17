import 'package:flutter/material.dart';
import 'services/apiservice.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  List data = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUpcoming();
  }

  Future<void> fetchUpcoming() async {
    setState(() => isLoading = true);

    try {
      final result = await ApiService.getUpcoming();

      setState(() {
        data = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("ERROR: $e");
      setState(() => isLoading = false);
    }
  }

  List filter(String type) =>
      data.where((e) => e["status_text"] == type).toList();

  List upcomingList() =>
      data.where((e) =>
      e["status_text"] != "Today" &&
          e["status_text"] != "Tomorrow")
          .toList();

  Color statusColor(String status) {
    if (status.toLowerCase() == "today") return const Color(0xFFD32F2F); // strong red
    if (status.toLowerCase() == "tomorrow") return const Color(0xFFF57C00); // strong orange
    return const Color(0xFF2E7D32); // strong green
  }

  String safe(Map item, String key) {
    return item[key]?.toString() ?? "-";
  }

  // 🔥 STRONG COLOR CARD
  Widget topCard(String title, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 6),
            Text(
              "$count",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  void showDetails(Map item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                controller: scrollController,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("Field")),
                    DataColumn(label: Text("Value")),
                  ],
                  rows: item.entries.map((e) {
                    return DataRow(cells: [
                      DataCell(Text(e.key)),
                      DataCell(Text(e.value?.toString() ?? "-")),
                    ]);
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayCount = filter("Today").length;
    final tomorrowCount = filter("Tomorrow").length;
    final upcomingCount = upcomingList().length;
    final totalCount = data.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [

          // 🔥 HEADER
          Container(
            color: const Color(0xFF0D47A1), // deep blue
            padding: const EdgeInsets.only(
                top: 40, left: 12, right: 12, bottom: 16),
            child: Column(
              children: [

                // 🎨 TITLE
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.trending_up, color: Colors.white), // 🔁 replaced icon
                    SizedBox(width: 6),
                    Text(
                      "Upcoming",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 🔢 TOTAL
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Total: $totalCount",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 🎨 BUTTONS
                Row(
                  children: [
                    topCard("Today", todayCount,
                        const Color(0xFFD32F2F), Icons.warning),
                    topCard("Tomorrow", tomorrowCount,
                        const Color(0xFFF57C00), Icons.event),
                    topCard("Upcoming", upcomingCount,
                        const Color(0xFF2E7D32), Icons.trending_up),
                  ],
                ),
              ],
            ),
          ),

          // 🔥 LIST
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchUpcoming,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final item = data[index];
                  final status =
                      item["status_text"]?.toString() ?? "UPCOMING";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: ListTile(
                      onTap: () => showDetails(item),

                      leading: CircleAvatar(
                        backgroundColor:
                        statusColor(status).withOpacity(0.2),
                        child: Icon(Icons.build,
                            color: statusColor(status)),
                      ),

                      title: Text(
                        "ID: ${item["id"] ?? "-"}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),

                      subtitle:
                      Text(safe(item, "location_name")),

                      trailing: const Icon(Icons.arrow_forward_ios,
                          size: 16),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}