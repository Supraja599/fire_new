import 'package:flutter/material.dart';
import 'package:fire_new/guided_capture_wizard.dart';

import 'package:mobile_scanner/mobile_scanner.dart';
import 'checklist.dart';
import 'services/fire_trolley_api_service.dart';
import 'package:fire_new/local_db.dart';

class FireTrolleyInspectionPage extends StatefulWidget {
  const FireTrolleyInspectionPage({super.key});

  @override
  State<FireTrolleyInspectionPage> createState() => _FireTrolleyInspectionPageState();
}

class _FireTrolleyInspectionPageState extends State<FireTrolleyInspectionPage> {
  final api = FireTrolleyApiService();
  final TextEditingController idController = TextEditingController();

  List<Map<String, dynamic>> allEquipment = [];
  List<Map<String, dynamic>> filteredEquipment = [];
  Map<String, dynamic>? item;
  bool loading = false;
  String? error;
  bool showScanner = false;
  bool showSearch = true;

  @override
  void initState() {
    super.initState();
    _loadAllEquipment();
  }

  Future<void> _loadAllEquipment() async {
    final list = await api.getEquipmentList();
    setState(() => allEquipment = list);
  }

  void _onSearchChanged(String val) {
    if (val.isEmpty) {
      setState(() => filteredEquipment = []);
      return;
    }
    final results = allEquipment.where((e) {
      final id = (e["sos_code"] ?? e["equipment_id"] ?? e["id"] ?? "").toString().toLowerCase();
      return id.contains(val.toLowerCase());
    }).take(5).toList();
    
    setState(() => filteredEquipment = results);

    final exactMatch = allEquipment.firstWhere(
      (e) => (e["sos_code"] ?? e["equipment_id"] ?? e["id"] ?? "").toString().toLowerCase() == val.toLowerCase(),
      orElse: () => {},
    );
    if (exactMatch.isNotEmpty) {
      fetchDetails(val);
    }
  }

  Future<void> fetchDetails(String input) async {
    if (input.trim().isEmpty) return;
    setState(() {
      loading = true;
      error = null;
      showSearch = false;
      filteredEquipment = [];
    });

    try {
      Map<String, dynamic>? data;
      final searchId = input; // moved outside nested try
      try {
        data = allEquipment.firstWhere((e) => (e["sos_code"] ?? e["equipment_id"] ?? e["id"])?.toString() == searchId);
      } catch (_) {
        data = await api.getEquipmentByQuery(searchId);
      }
      if (data == null) {
        setState(() {
          loading = false;
          error = "No fire trolley found for this ID";
          showSearch = true;
        });
        return;
      }
      setState(() {
        item = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = "Error: $e";
        showSearch = true;
      });
    }
  }

  void onDetect(BarcodeCapture capture) {
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;
    setState(() {
      showScanner = false;
      idController.text = raw;
    });
    fetchDetails(raw);
  }

  Future<void> _submitInspection() async {
    if (item == null) return;
    await LocalDB.saveSingleModuleRecord(
      moduleCode: "fire_trolley",
      recordType: "equipment",
      item: item!,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fire Trolley Inspection Saved Locally")));
  }

  Widget buildDetails() {
    final sosId = item!["sos_code"] ?? item!["equipment_id"] ?? item!["id"] ?? "-";
    final location = item!["location_name"] ?? "General Area";
    final Map<String, String> displayFields = {};
    
    void flatten(Map<dynamic, dynamic> map, [String prefix = ""]) {
      map.forEach((key, value) {
        final displayKey = prefix.isEmpty ? key.toString() : "${prefix}_$key";
        if (value is Map) flatten(value, displayKey);
        else if (value != null && value is! List) displayFields[displayKey] = value.toString();
      });
    }
    flatten(item!);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
            border: Border.all(color: Colors.red.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: Colors.red.shade800, borderRadius: BorderRadius.circular(12)),
                    child: Text(sosId.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                  ),
                  const Icon(Icons.trolley, color: Colors.red, size: 28),
                ],
              ),
              const SizedBox(height: 15),
              Align(alignment: Alignment.centerLeft, child: Text(location, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87))),
              const Divider(height: 30),
              Table(
                columnWidths: const {0: FlexColumnWidth(4), 1: FlexColumnWidth(6)},
                children: displayFields.entries.map((e) => TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(e.key.replaceAll("_", " ").toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey))),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(e.value, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                  ],
                )).toList(),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE8E8),
      appBar: AppBar(
        title: const Text("Trolley Inspection", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red.shade800,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() { item = null; idController.clear(); error = null; showSearch = true; filteredEquipment = []; })),
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: [
            if (showSearch)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                child: Column(
                  children: [
                    TextField(
                      controller: idController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: "Enter SOS ID (e.g. SOS-TRL-01)",
                        prefixIcon: const Icon(Icons.search, color: Colors.red),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    if (filteredEquipment.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredEquipment.length,
                        itemBuilder: (context, i) {
                          final e = filteredEquipment[i];
                          return ListTile(
                            dense: true,
                            title: Text((e["sos_code"] ?? e["id"] ?? "-").toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(e["location_name"]?.toString() ?? "General Area"),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: () {
                              idController.text = (e["sos_code"] ?? e["id"]).toString();
                              fetchDetails(idController.text);
                            },
                          );
                        },
                      ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: () => fetchDetails(idController.text),
                            child: const Text("FETCH DETAILS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: Icon(Icons.qr_code_scanner, color: Colors.red.shade800, size: 36),
                          onPressed: () => setState(() => showScanner = !showScanner),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (showScanner) 
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                height: 220,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.red, width: 2)),
                child: ClipRRect(borderRadius: BorderRadius.circular(23), child: MobileScanner(onDetect: onDetect)),
              ),
            if (loading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.red))),
            if (error != null) Center(child: Padding(padding: EdgeInsets.all(20), child: Text(error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))),
            if (item != null) buildDetails()
            else if (!loading && error == null)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.search, size: 80, color: Colors.grey), Text("Enter SOS ID to begin", style: TextStyle(color: Colors.grey))]))),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                icon: const Icon(Icons.checklist_rtl, color: Colors.white),
                label: const Text("CHECKLIST", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                onPressed: () {
            if (item != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => FireTrolleyChecklistPage(selectedEquipment: item)));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => GuidedCaptureWizardPage(
                selectedEquipment: item,
                equipmentImage: 'assets/fire_trolley.png',
                nextScreen: FireTrolleyChecklistPage(selectedEquipment: item),
              )));
            }
          },
              ),
            ),
            if (item != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  icon: const Icon(Icons.cloud_done, color: Colors.white),
                  label: const Text("SUBMIT", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  onPressed: _submitInspection,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
