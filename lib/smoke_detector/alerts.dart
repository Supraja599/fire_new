import 'package:flutter/material.dart';
import 'services/smoke_detector_api_service.dart';

class SmokeDetectorAlertsPage extends StatefulWidget {
  const SmokeDetectorAlertsPage({super.key});

  @override
  State<SmokeDetectorAlertsPage> createState() => _SmokeDetectorAlertsPageState();
}

class _SmokeDetectorAlertsPageState extends State<SmokeDetectorAlertsPage> {
  final api = SmokeDetectorApiService();
  List<Map<String, dynamic>> alerts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final list = await api.getAlerts();
    if (!mounted) return;
    setState(() {
      alerts = list;
      isLoading = false;
    });
  }

  void _showDetail(Map<String, dynamic> alert) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("ALERT INFORMATION", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.red)),
            const Divider(),
            _infoRow("Type", alert["type"] ?? "Fire Alert"),
            _infoRow("Equipment ID", alert["equipment_id"] ?? "SYS-101"),
            _infoRow("Message", alert["message"] ?? "Smoke detected in Zone 4"),
            _infoRow("Priority", alert["priority"] ?? "Critical"),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: () => Navigator.pop(context),
              child: const Text("ACKNOWLEDGE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Text("$l: ", style: const TextStyle(fontWeight: FontWeight.bold)), Expanded(child: Text(v))]));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDECEA),
      appBar: AppBar(backgroundColor: Colors.white, elevation: 1, title: const Text("Safety Alerts", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), iconTheme: const IconThemeData(color: Colors.red)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
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
                              child: Image.asset('assets/smoke_detector.png', errorBuilder: (c, e, s) => Icon(Icons.warning_amber_rounded, color: color, size: 35)),
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
                                    (alert["equipment_id"] ?? alert["sos_code"] ?? "SYS-ALERT").toString(),
                                    style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(alert["message"] ?? "System Notification", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
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
            child: Image.asset('assets/smoke_detector.png', width: 120, height: 120, color: Colors.grey.withOpacity(0.3), colorBlendMode: BlendMode.modulate),
          ),
          const SizedBox(height: 30),
          const Text("ALL CLEAR", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 2)),
          const SizedBox(height: 10),
          const Text("No safety alerts recorded for today.", style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _loadAlerts,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
            child: const Text("REFRESH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
