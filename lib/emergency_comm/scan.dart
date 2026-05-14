import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../local_db.dart';
import 'checklist.dart';
import 'services/api_service.dart';

class EmergencyCommScanPage extends StatefulWidget {
  const EmergencyCommScanPage({super.key});
  @override
  State<EmergencyCommScanPage> createState() => _EmergencyCommScanPageState();
}

class _EmergencyCommScanPageState extends State<EmergencyCommScanPage> {
  final TextEditingController idController = TextEditingController();
  final api = EmergencyCommApiService();
  Map<String, dynamic>? item;
  bool loading = false;
  bool showScanner = false;
  List<Map<String, dynamic>> suggestions = [];
  List<Map<String, dynamic>> allEquipment = [];

  @override
  void initState() { super.initState(); _loadCache(); }
  Future<void> _loadCache() async { final list = await api.getEquipmentList(); setState(() => allEquipment = list); }

  void _onSearchChanged(String val) {
    if (val.isEmpty) { setState(() => suggestions = []); return; }
    setState(() { suggestions = allEquipment.where((e) => (e["sos_code"]?.toString() ?? e["equipment_id"]?.toString() ?? e["id"]?.toString() ?? "").toUpperCase().contains(val.toUpperCase())).take(5).toList(); });
  }

  Future<void> _fetchDetails(String code) async {
    if (code.isEmpty) return;
    setState(() { loading = true; suggestions = []; showScanner = false; });
    Map<String, dynamic>? res;
    try {
      res = allEquipment.firstWhere((e) => e["sos_code"]?.toString() == code || e["equipment_id"]?.toString() == code || e["id"]?.toString() == code);
    } catch (_) {
      res = await api.getEquipmentByQuery(code);
    }
    setState(() { item = res; loading = false; });
    if (res == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No equipment found"))); }
  }

  void _editDetails() {
    if (item == null) return;
    final controllers = <String, TextEditingController>{};
    item!.forEach((key, value) { controllers[key] = TextEditingController(text: value?.toString() ?? ""); });
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Edit Details"),
      content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(child: Column(children: controllers.entries.where((e) => !e.key.contains("id")).map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: TextField(controller: e.value, decoration: InputDecoration(labelText: e.key.toUpperCase(), border: const OutlineInputBorder())))).toList()))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () async {
          controllers.forEach((key, controller) { item![key] = controller.text; });
          await LocalDB.saveSingleModuleRecord(moduleCode: EmergencyCommApiService.moduleCode, recordType: "equipment", item: item!);
          setState(() {}); Navigator.pop(c); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updated locally (Offline)")));
        }, child: const Text("SAVE", style: TextStyle(color: Colors.white)))
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text("Inspection System"), backgroundColor: Colors.red, actions: [if (item != null) IconButton(icon: const Icon(Icons.edit), onPressed: _editDetails), IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() { item = null; idController.clear(); suggestions = []; showScanner = false; }))]),
      body: SingleChildScrollView(child: Column(children: [
        Container(margin: const EdgeInsets.all(15), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: Column(children: [
          TextField(controller: idController, onChanged: _onSearchChanged, decoration: InputDecoration(hintText: "Enter SOS ID (Ex: EXT-101)", border: const OutlineInputBorder(), suffixIcon: IconButton(icon: const Icon(Icons.qr_code_scanner, color: Colors.red), onPressed: () => setState(() => showScanner = !showScanner)))),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _fetchDetails(idController.text), child: const Text("SEARCH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
          if (suggestions.isNotEmpty) ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: suggestions.length, itemBuilder: (c, i) => ListTile(dense: true, title: Text(suggestions[i]["sos_code"] ?? suggestions[i]["equipment_id"] ?? suggestions[i]["id"] ?? "-"), subtitle: Text(suggestions[i]["location_name"] ?? "-", style: const TextStyle(fontSize: 10)), onTap: () { idController.text = suggestions[i]["sos_code"] ?? suggestions[i]["equipment_id"] ?? suggestions[i]["id"] ?? ""; _fetchDetails(idController.text); })),
        ])),
        if (showScanner) Container(margin: const EdgeInsets.all(15), height: 200, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.red, width: 2)), child: ClipRRect(borderRadius: BorderRadius.circular(20), child: MobileScanner(onDetect: (c) { if (c.barcodes.isNotEmpty) { idController.text = c.barcodes.first.rawValue ?? ""; _fetchDetails(idController.text); } }))),
        if (loading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
        if (item != null) Container(margin: const EdgeInsets.symmetric(horizontal: 15), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(children: [
          Text(item!["sos_code"] ?? item!["equipment_id"] ?? item!["id"] ?? "-", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
          const Divider(height: 30),
          ...item!.entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [Expanded(flex: 4, child: Text(e.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey))), Expanded(flex: 6, child: Text(e.value?.toString() ?? "-"))]))).toList(),
          ])),
        const SizedBox(height: 50),
      ])),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          icon: const Icon(Icons.list, color: Colors.white),
          label: const Text("OPEN CHECKLIST", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencyCommChecklistPage(selectedEquipment: item))),
        ),
      ),
    );
  }
}

