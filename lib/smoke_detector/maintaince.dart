import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';
class SmokeDetectorMaintenancePage extends StatefulWidget {
  const SmokeDetectorMaintenancePage({super.key});

  @override
  State<SmokeDetectorMaintenancePage> createState() => _SmokeDetectorMaintenancePageState();
}

class _SmokeDetectorMaintenancePageState extends State<SmokeDetectorMaintenancePage> {
  final api = ModuleApiService.smokeDetector;
  List<Map<String, dynamic>> records = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await api.getEquipmentList(); // Simplified for maintenance context
    if (!mounted) return;
    setState(() {
      records = list;
      isLoading = false;
    });
  }

  void _showDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(25),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text("MAINTENANCE DETAILS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.orange)),
              const Divider(),
              ...item.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: Text(e.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(flex: 6, child: Text(e.value?.toString() ?? "-")),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Detector Maintenance", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final item = records[index];
                return GestureDetector(
                  onTap: () => _showDetails(item),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 80,
                            height: 90,
                            color: Colors.orange.withOpacity(0.08),
                            child: Image.asset('assets/smoke_detector.webp', fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.build, color: Colors.orange, size: 30)),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.withOpacity(0.2))),
                                  child: Text(
                                    (item["sos_code"] ?? item["equipment_id"] ?? item["sos_id"] ?? item["id"] ?? "-").toString(),
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.orange, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(item["location_name"]?.toString() ?? "General Area", style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.event_note, size: 12, color: Colors.orange.shade300),
                                    const SizedBox(width: 4),
                                    Text("Service Due: ${item["next_service_date"] ?? "Scheduled"}", style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                        const SizedBox(width: 15),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
