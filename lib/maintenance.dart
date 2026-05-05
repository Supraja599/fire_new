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
      // 🚀 Using getAll() to ensure we get all extinguishers, same as Hydrant module
      final result = await ApiService.getAll();

      final filtered = result.where((item) {
        final status = item["status_bucket"]?.toString().toLowerCase() ?? "";
        
        // 🔥 Show items that need service or inspection, but exclude expired
        return (status == "needs-service" || status == "due-inspection") && status != "expired";
      }).toList();

      setState(() {
        data = filtered;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching extinguishers: $e");
      setState(() => isLoading = false);
    }
  }

  Color statusColor(String status) {
    status = status.toLowerCase();
    if (status == "today") return const Color(0xFFD32F2F);
    if (status == "tomorrow") return const Color(0xFFF57C00);
    return const Color(0xFF2E7D32);
  }

  void showDetails(Map item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.build_circle_outlined, color: Colors.blue, size: 40),
              const SizedBox(height: 10),
              _detailRow("SOS ID", (item["sos_code"] ?? item["serial_number"] ?? item["id"] ?? "-").toString()),
              _detailRow("Location", (item["location_name"] ?? "-").toString()),
              _detailRow("Type", (item["extinguisher_type"] ?? "-").toString()),
              _detailRow("Status", (item["status_text"] ?? "-").toString()),
              _detailRow("Next Due", (item["next_inspection_due"] ?? "-").toString()),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String a, String b) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(a, style: const TextStyle(fontWeight: FontWeight.w700))),
          Expanded(flex: 6, child: Text(b)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Extinguisher Maintenance", style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchUpcoming,
              child: data.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              'assets/extinguisher.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.contain,
                              opacity: const AlwaysStoppedAnimation(0.5),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "No Upcoming Maintenance",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "All extinguishers are in good health!",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final item = data[index];
                        final status = item["status_text"]?.toString() ?? "UPCOMING";
                        final color = statusColor(status);
                        final sosId = item["sos_code"] ?? item["serial_number"] ?? item["id"] ?? "-";

                        return GestureDetector(
                          onTap: () => showDetails(item),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                // 🖼️ EXTINGUISHER IMAGE
                                ClipRRect(
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                                  child: Container(
                                    width: 96,
                                    height: 108,
                                    color: color.withValues(alpha: 0.08),
                                    child: Image.asset(
                                      'assets/extinguisher.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(Icons.fire_extinguisher, color: color, size: 40);
                                      },
                                    ),
                                  ),
                                ),
                                
                                // 📝 DETAILS
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "SOS ID: $sosId",
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item["location_name"]?.toString() ?? "Unknown Location",
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _chip(status, color),
                                            _chip(
                                              "Due: ${item["next_inspection_due"] ?? "-"}",
                                              Colors.grey.shade700,
                                            ),
                                          ],
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
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}