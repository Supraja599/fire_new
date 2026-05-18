import 'package:flutter/material.dart';
import 'package:fire_new/guided_capture_wizard.dart';

import 'package:mobile_scanner/mobile_scanner.dart';
import 'checklist.dart';
import 'services/hydrant_api_service.dart';
import 'package:fire_new/local_db.dart';

class HydrantScanPage extends StatefulWidget {
  const HydrantScanPage({super.key});

  @override
  State<HydrantScanPage> createState() => _HydrantScanPageState();
}

class _HydrantScanPageState extends State<HydrantScanPage> {
  final api = HydrantApiService();
  final TextEditingController idController = TextEditingController();

  List<Map<String, dynamic>> allEquipment = [];
  List<Map<String, dynamic>> filteredEquipment = [];
  Map<String, dynamic>? item;
  bool loading = false;
  String? error;
  bool showScanner = true;
  bool showSearch = false;

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
        data = allEquipment.firstWhere((e) => (e["sos_code"] ?? e["serial_number"] ?? e["id"])?.toString() == searchId);
      } catch (_) {
        data = await api.getEquipmentByQuery(searchId);
      }
      if (data == null) {
        setState(() {
          loading = false;
          error = "No hydrant found for this ID";
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
      moduleCode: "hydrant",
      recordType: "equipment",
      item: item!,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hydrant Inspection Saved Locally")));
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
                    decoration: BoxDecoration(color: const Color(0xFFB71C1C), borderRadius: BorderRadius.circular(12)),
                    child: Text(sosId.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                  ),
                  const Icon(Icons.water_drop, color: Colors.red, size: 28),
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
        title: const Text("Hydrant Inspection", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFB71C1C),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() { item = null; idController.clear(); error = null; showSearch = true; filteredEquipment = []; })),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (item == null && !loading) ...[
              // 1. Camera Scanner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.red, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.08),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: MobileScanner(
                    onDetect: (c) {
                      if (c.barcodes.isNotEmpty) {
                        idController.text = c.barcodes.first.rawValue ?? "";
                        fetchDetails(idController.text);
                      }
                    },
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Text(
                  "📷 Align the barcode / QR code inside the frame to inspect automatically.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey,
                  ),
                ),
              ),

              // 2. Separator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300, indent: 30, endIndent: 10)),
                    Text(
                      "OR ENTER MANUALLY",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300, indent: 10, endIndent: 30)),
                  ],
                ),
              ),

              // 3. Manual Entry Search Box
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: idController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: "Enter SOS ID",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        prefixIcon: const Icon(Icons.search, color: Colors.red),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => fetchDetails(idController.text),
                        child: const Text("FETCH DETAILS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    if (filteredEquipment.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredEquipment.length,
                        itemBuilder: (c, i) => ListTile(
                          dense: true,
                          title: Text(filteredEquipment[i]["sos_code"] ?? filteredEquipment[i]["equipment_id"] ?? filteredEquipment[i]["id"] ?? filteredEquipment[i]["serial_number"] ?? "-"),
                          subtitle: Text(filteredEquipment[i]["location_name"] ?? "-", style: const TextStyle(fontSize: 10)),
                          onTap: () {
                            idController.text = filteredEquipment[i]["sos_code"] ?? filteredEquipment[i]["equipment_id"] ?? filteredEquipment[i]["id"] ?? filteredEquipment[i]["serial_number"] ?? "";
                            fetchDetails(idController.text);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (loading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.red))),
            if (item != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    Text(
                      item!["sos_code"] ?? item!["equipment_id"] ?? item!["id"] ?? item!["serial_number"] ?? "-",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const Divider(height: 30),
                    ...item!.entries.map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              e.key.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey),
                            ),
                          ),
                          Expanded(flex: 6, child: Text(e.value?.toString() ?? "-")),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),
            const SizedBox(height: 50),
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
              Navigator.push(context, MaterialPageRoute(builder: (_) => HydrantChecklistPage(selectedEquipment: item)));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => GuidedCaptureWizardPage(
                selectedEquipment: item,
                equipmentImage: 'assets/firehydrant.png',
                nextScreen: HydrantChecklistPage(selectedEquipment: item),
              )));
            }
          },
              ),
            ),
            if (item != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
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
