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
          e["status_text"] != "Tomorrow").toList();

  Color statusColor(String status) {
    if (status.toLowerCase() == "today") return Colors.red;
    if (status.toLowerCase() == "tomorrow") return Colors.orange;
    return Colors.green;
  }

  String safe(Map item, String key) {
    return item[key]?.toString() ?? "-";
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
          minChildSize: 0.3,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                controller: scrollController,
                child: DataTable(
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(label: Text("Field")),
                    DataColumn(label: Text("Value")),
                  ],
                  rows: [
                    row("ID", item["id"]),
                    row("Barcode", item["barcode"]),
                    row("Equipment Code", item["equipment_code"]),
                    row("Serial Number", item["serial_number"]),
                    row("Type", item["extinguisher_type"]),
                    row("Capacity", item["capacity_kg"]),
                    row("Location", item["location_name"]),
                    row("Building", item["building_name"]),
                    row("Floor", item["floor_name"]),
                    row("Zone", item["zone_name"]),
                    row("Department", item["department_name"]),
                    row("Manufacturer", item["manufacturer_name"]),
                    row("Installed", item["installed_on"]),
                    row("Last Service", item["last_service_on"]),
                    row("Next Inspection", item["next_inspection_due"]),
                    row("Expiry", item["expiry_date"]),
                    row("Pressure", item["pressure_status"]),
                    row("Hose", item["hose_status"]),
                    row("Pin Seal", item["pin_seal_status"]),
                    row("Body", item["body_status"]),
                    row("Score", item["readiness_score"]),
                    row("Status", item["operational_status"]),
                    row("Remarks", item["remarks"]),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  DataRow row(String key, dynamic value) {
    return DataRow(cells: [
      DataCell(Text(key)),
      DataCell(Text(value?.toString() ?? "-")),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Column(
          children: [
            // ✅ BACK BUTTON + TITLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Upcoming",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // balance spacing
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: fetchUpcoming,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      buildSection("Today", filter("Today"), Colors.red),
                      buildSection("Tomorrow", filter("Tomorrow"), Colors.orange),
                      buildSection("Upcoming", upcomingList(), Colors.green),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSection(String title, List list, Color color) {
    if (list.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            final status = item["status_text"]?.toString() ?? "UPCOMING";

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              child: ListTile(
                onTap: () => showDetails(item),

                leading: CircleAvatar(
                  backgroundColor: statusColor(status).withOpacity(0.2),
                  child: Icon(
                    Icons.build_circle_rounded,
                    color: statusColor(status),
                  ),
                ),

                title: Text(
                  "ID: ${item["id"] ?? "-"}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 3),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor(status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      safe(item, "location_name"),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),

                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            );
          },
        ),
      ],
    );
  }
}