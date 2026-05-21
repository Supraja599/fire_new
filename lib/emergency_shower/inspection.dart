import 'package:flutter/material.dart';
import 'package:fire_new/guided_capture_wizard.dart';

import 'package:mobile_scanner/mobile_scanner.dart';
import 'checklist.dart';
import 'services/api_service.dart';
import 'package:fire_new/local_db.dart';

class EmergencyShowerInspectionPage extends StatefulWidget {
  final String? preScannedId;
  const EmergencyShowerInspectionPage({super.key, this.preScannedId});

  @override
  State<EmergencyShowerInspectionPage> createState() => _EmergencyShowerInspectionPageState();
}

class _EmergencyShowerInspectionPageState extends State<EmergencyShowerInspectionPage> {
  final api = EmergencyShowerApiService();
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
    _loadAllEquipment().then((_) {
      if (widget.preScannedId != null && widget.preScannedId!.isNotEmpty) {
        idController.text = widget.preScannedId!;
        fetchDetails(widget.preScannedId!);
      }
    });
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
      final searchId = input;
      try {
        data = allEquipment.firstWhere((e) => (e["sos_code"] ?? e["equipment_id"] ?? e["id"])?.toString() == searchId);
      } catch (_) {
        data = await api.getEquipmentByQuery(searchId);
      }
      if (data == null) {
        setState(() {
          loading = false;
          error = "No Emergency Shower found for this ID";
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

  Future<void> _submitInspection() async {
    if (item == null) return;
    await LocalDB.saveSingleModuleRecord(
      moduleCode: "emergency_shower",
      recordType: "equipment",
      item: item!,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Emergency Shower Inspection Saved Locally")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Emergency Shower Inspection", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {
              item = null;
              idController.clear();
              error = null;
              showSearch = true;
              filteredEquipment = [];
            }),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (item == null && !loading) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: const Color(0xFF1976D2), width: 2.5),
                  boxShadow: [BoxShadow(color: const Color(0xFF1976D2).withValues(alpha: 0.08), blurRadius: 15)],
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
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(children: [
                  Expanded(child: Divider(color: Colors.grey.shade300, indent: 30, endIndent: 10)),
                  Text("OR ENTER MANUALLY",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  Expanded(child: Divider(color: Colors.grey.shade300, indent: 10, endIndent: 30)),
                ]),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                ),
                child: Column(children: [
                  TextField(
                    controller: idController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: "Enter SOS ID",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      prefixIcon: Icon(Icons.search, color: const Color(0xFF1976D2)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
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
                ]),
              ),
            ],
            if (loading) Center(child: Padding(padding: const EdgeInsets.all(20), child: CircularProgressIndicator(color: const Color(0xFF1976D2)))),
            if (item != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(children: [
                  Text(
                    item!["sos_code"] ?? item!["equipment_id"] ?? item!["id"] ?? item!["serial_number"] ?? "-",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1976D2)),
                  ),
                  const Divider(height: 30),
                  ...item!.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      Expanded(flex: 4, child: Text(e.key.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey))),
                      Expanded(flex: 6, child: Text(e.value?.toString() ?? "-")),
                    ]),
                  )).toList(),
                ]),
              ),
            const SizedBox(height: 50),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              icon: const Icon(Icons.checklist_rtl, color: Colors.white),
              label: const Text("CHECKLIST", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              onPressed: () {
                if (item != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencyShowerChecklistPage(selectedEquipment: item)));
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => GuidedCaptureWizardPage(
                    selectedEquipment: item,
                    equipmentImage: 'assets/emergency_shower.png',
                    nextScreen: EmergencyShowerChecklistPage(selectedEquipment: item),
                  )));
                }
              },
            ),
          ),
          if (item != null) ...[
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                icon: const Icon(Icons.cloud_done, color: Colors.white),
                label: const Text("SUBMIT", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                onPressed: _submitInspection,
              ),
            ),
          ],
        ]),
      ),
    );
  }
}