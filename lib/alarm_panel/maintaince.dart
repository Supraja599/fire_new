import 'package:flutter/material.dart';
import 'services/alarm_panel_api_service.dart';

class AlarmPanelMaintenancePage extends StatefulWidget {
  const AlarmPanelMaintenancePage({super.key});

  @override
  State<AlarmPanelMaintenancePage> createState() => _AlarmPanelMaintenancePageState();
}

class _AlarmPanelMaintenancePageState extends State<AlarmPanelMaintenancePage> {
  final api = AlarmPanelApiService();
  List<Map<String, dynamic>> maintenanceList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final list = await api.getEquipmentList();
      if (!mounted) return;
      setState(() {
        maintenanceList = list.where((e) => e["status"]?.toString().toLowerCase() != "active").toList();
        isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showDetails(Map<String, dynamic> item) {
    final Map<String, String> displayFields = {};
    void flatten(Map<dynamic, dynamic> map, [String prefix = ""]) {
      map.forEach((key, value) {
        final displayKey = prefix.isEmpty ? key.toString() : "${prefix}_$key";
        if (value is Map) flatten(value, displayKey);
        else if (value != null && value is! List) displayFields[displayKey] = value.toString();
      });
    }
    flatten(item);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Text("Service Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.orange.shade800)),
            const Divider(height: 30),
            Expanded(
              child: ListView(
                children: displayFields.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: Text(e.key.replaceAll("_", " ").toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey))),
                      Expanded(flex: 6, child: Text(e.value, style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7E6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text("Panel Maintenance", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.orange),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : maintenanceList.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: maintenanceList.length,
                  itemBuilder: (context, index) {
                    final item = maintenanceList[index];
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
                                child: Image.asset('assets/alarm_panel.png', fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.build, color: Colors.orange, size: 30)),
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
                                        (item["sos_code"] ?? item["equipment_id"] ?? item["id"] ?? "-").toString(),
                                        style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.orange, fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(item["location_name"]?.toString() ?? "Panel Location", style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.event_note, size: 12, color: Colors.orange.shade300),
                                        const SizedBox(width: 4),
                                        Text("Next Service: ${item["next_service_date"] ?? "Scheduled"}", style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
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

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified, size: 80, color: Colors.green.withOpacity(0.3)),
          const SizedBox(height: 20),
          const Text("ALL PANELS HEALTHY", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const Text("No pending maintenance tasks found.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
