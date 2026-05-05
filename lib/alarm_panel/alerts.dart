import 'package:flutter/material.dart';
import 'services/alarm_panel_api_service.dart';

class AlarmPanelAlertsPage extends StatefulWidget {
  const AlarmPanelAlertsPage({super.key});

  @override
  State<AlarmPanelAlertsPage> createState() => _AlarmPanelAlertsPageState();
}

class _AlarmPanelAlertsPageState extends State<AlarmPanelAlertsPage> {
  final api = AlarmPanelApiService();
  List<Map<String, dynamic>> alerts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final list = await api.getAlerts();
      if (!mounted) return;
      setState(() {
        alerts = list;
        isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showDetail(Map<String, dynamic> alert) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Text("Alert Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
            const Divider(height: 30),
            _infoRow("Equipment", alert["equipment_id"] ?? "N/A"),
            _infoRow("Message", alert["message"] ?? "No details provided"),
            _infoRow("Status", alert["status"] ?? "Active"),
            _infoRow("Time", alert["created_at"] ?? "Recently"),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(vertical: 15)),
                child: const Text("ACKNOWLEDGE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [Text("$l: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)), Expanded(child: Text(v, style: const TextStyle(color: Colors.black87)))]));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE8E8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text("System Alerts", style: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFFB71C1C)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFB71C1C)))
          : alerts.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index];
                    final color = alert["priority"] == "Critical" ? Colors.red : Colors.orange;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              width: 60,
                              height: 60,
                              color: color.withOpacity(0.1),
                              child: Image.asset('assets/alarm_panel.png', errorBuilder: (c, e, s) => Icon(Icons.warning_amber_rounded, color: color, size: 35)),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                    (alert["equipment_id"] ?? alert["sos_code"] ?? "SYS-PANEL").toString(),
                                    style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(alert["message"] ?? "Fault Detected", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                                Text(alert["created_at"] ?? "Just now", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
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
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.05), blurRadius: 30)]),
            child: Image.asset('assets/alarm_panel.png', width: 120, height: 120, color: Colors.grey.withOpacity(0.3), colorBlendMode: BlendMode.modulate),
          ),
          const SizedBox(height: 30),
          const Text("SYSTEM SECURE", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)),
          const SizedBox(height: 10),
          const Text("No active faults or alerts for today.", style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _loadAlerts,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
            child: const Text("REFRESH STATUS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
