import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'services/api_service.dart';

class PPECabinetsPlantHealthPage extends StatefulWidget {
  const PPECabinetsPlantHealthPage({super.key});
  @override
  State<PPECabinetsPlantHealthPage> createState() => _PPECabinetsPlantHealthPageState();
}

class _PPECabinetsPlantHealthPageState extends State<PPECabinetsPlantHealthPage> {
  final api = PPECabinetsApiService();
  int active = 0, service = 0, inspect = 0, expired = 0;
  List<Map<String, dynamic>> equipment = [];
  bool isLoading = true;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    try {
      final res = await Future.wait([api.getSummary(), api.getEquipmentList()]);
      final s = res[0] as Map<String, dynamic>;
      if (mounted) setState(() {
        active = s["active_units"] ?? s["active"] ?? 0;
        service = s["needs_service"] ?? 0;
        inspect = s["due_inspection"] ?? 0;
        expired = s["expired_units"] ?? s["expired"] ?? 0;
        equipment = res[1] as List<Map<String, dynamic>>;
        isLoading = false;
      });
    } catch (_) { if (mounted) setState(() => isLoading = false); }
  }

  void _openStatusList(String s, String t, Color c) {
    final list = equipment.where((item) => (item["status_bucket"]?.toString() ?? item["status"]?.toString() ?? "").toLowerCase().contains(s.toLowerCase())).toList();
    Navigator.push(context, MaterialPageRoute(builder: (_) => _PPECabinetsStatusListPage(title: t, color: c, icon: Icons.medical_services, items: list, asset: "assets/ppe_cabinets.png")));
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(backgroundColor: Colors.white, elevation: 1, title: const Text("Health Analytics", style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Row(children: [_box("ACTIVE", active, Colors.green, () => _openStatusList("active", "Active PPECabinets", Colors.green)), const SizedBox(width: 12), _box("SERVICE", service, Colors.orange, () => _openStatusList("needs-service", "Needs Service", Colors.orange))]),
          const SizedBox(height: 12),
          Row(children: [_box("INSPECT", inspect, Colors.blue, () => _openStatusList("due-inspection", "Due Inspection", Colors.blue)), const SizedBox(width: 12), _box("EXPIRED", expired, Colors.red, () => _openStatusList("expired", "Expired PPECabinets", Colors.red))]),
          const SizedBox(height: 30),
          Container(
            height: 450, padding: const EdgeInsets.all(25), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Performance Matrix", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1))),
              const SizedBox(height: 40),
              Expanded(child: BarChart(BarChartData(
                maxY: (active + service + inspect + expired).toDouble() + 10,
                barGroups: [
                  _bar(0, active, Colors.green), _bar(1, service, Colors.orange), _bar(2, inspect, Colors.blue), _bar(3, expired, Colors.red),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 8), child: Text(["ACTIVE", "SERVICE", "INSPECT", "EXPIRED"][v.toInt()], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))))),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: true, drawVerticalLine: false), borderData: FlBorderData(show: false),
              ))),
            ]),
          ),
        ]),
      ),
    );
  }

  BarChartGroupData _bar(int x, int v, Color c) => BarChartGroupData(x: x, barRods: [BarChartRodData(toY: v.toDouble(), color: c, width: 28, borderRadius: BorderRadius.circular(8))]);
  Widget _box(String t, int v, Color c, VoidCallback onTap) => Expanded(child: GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 25), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: c.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]), child: Column(children: [Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(height: 8), Text("$v", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900))]))));
}

class _PPECabinetsStatusListPage extends StatelessWidget {
  final String title; final Color color; final IconData icon; final List<Map<String, dynamic>> items; final String asset;
  const _PPECabinetsStatusListPage({required this.title, required this.color, required this.icon, required this.items, required this.asset});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(title: Text(title), backgroundColor: Colors.white),
      body: items.isEmpty ? const Center(child: Text("No items found")) : ListView.builder(padding: const EdgeInsets.all(12), itemCount: items.length, itemBuilder: (c, i) {
        final item = items[i];
        return GestureDetector(
          onTap: () => _showDetails(context, item),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
            child: Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset(asset, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c,e,s) => Icon(icon, color: color, size: 30))),
              const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item["sos_code"]?.toString() ?? item["id"]?.toString() ?? "-", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), Text(item["location_name"]?.toString() ?? "Main Building", style: TextStyle(color: Colors.grey.shade600, fontSize: 12))])),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ]),
          ),
        );
      }),
    );
  }
  void _showDetails(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))), builder: (_) => Container(padding: const EdgeInsets.all(24), height: MediaQuery.of(context).size.height * 0.7, child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Technical Specifications", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))]),
      const Divider(),
      Expanded(child: ListView(children: item.entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [Expanded(flex: 4, child: Text(e.key.toUpperCase(), style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 12))), Expanded(flex: 6, child: Text(e.value?.toString() ?? "-", style: const TextStyle(fontWeight: FontWeight.w500)))]))).toList())),
    ])));
  }
}

