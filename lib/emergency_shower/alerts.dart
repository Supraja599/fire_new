import 'package:flutter/material.dart';
import 'services/api_service.dart';

class EmergencyShowerAlertsPage extends StatefulWidget {
  const EmergencyShowerAlertsPage({super.key});
  @override
  State<EmergencyShowerAlertsPage> createState() => _EmergencyShowerAlertsPageState();
}

class _EmergencyShowerAlertsPageState extends State<EmergencyShowerAlertsPage> {
  final api = EmergencyShowerApiService();
  List<Map<String, dynamic>> alerts = [];
  bool isLoading = true;

  @override
  void initState() { super.initState(); _loadAlerts(); }
  Future<void> _loadAlerts() async { try { final list = await api.getAlerts(); if (mounted) setState(() { alerts = list; isLoading = false; }); } catch (_) { if (mounted) setState(() => isLoading = false); } }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(title: const Text("Safety Alerts"), backgroundColor: Colors.white, elevation: 1),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : alerts.isEmpty ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image.asset("assets/emergency_shower.png", height: 120, opacity: const AlwaysStoppedAnimation(0.3), errorBuilder: (c,e,s) => Icon(Icons.medical_services, size: 100, color: Colors.grey.shade300)),
        const SizedBox(height: 20),
        const Text("No active alerts found", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        const Text("System is running optimally", style: TextStyle(color: Colors.grey, fontSize: 12)),
      ])) : ListView.builder(padding: const EdgeInsets.all(12), itemCount: alerts.length, itemBuilder: (c, i) {
        final alert = alerts[i];
        final level = alert["level"] ?? 1;
        final color = level == 3 ? Colors.red : level == 2 ? Colors.orange : Colors.blue;
        return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.3))), child: Row(children: [Icon(Icons.warning, color: color, size: 30), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(alert["title"]?.toString() ?? "Alert", style: const TextStyle(fontWeight: FontWeight.bold)), Text(alert["message"]?.toString() ?? "Something needs attention")]))]));
      }),
    );
  }
}

