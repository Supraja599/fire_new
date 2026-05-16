import 'package:flutter/material.dart';
import 'package:fire_new/guided_capture_wizard.dart';

import 'package:mobile_scanner/mobile_scanner.dart';
import 'checklist.dart';
import 'services/smoke_detector_api_service.dart';
import 'package:fire_new/local_db.dart';

class SmokeDetectorInspectionPage extends StatefulWidget {
  const SmokeDetectorInspectionPage({super.key});

  @override
  State<SmokeDetectorInspectionPage> createState() => _SmokeDetectorInspectionPageState();
}

class _SmokeDetectorInspectionPageState extends State<SmokeDetectorInspectionPage> {
  final api = SmokeDetectorApiService();
  final TextEditingController idController = TextEditingController();

  List<Map<String, dynamic>> allEquipment = [];
  List<Map<String, dynamic>> filteredEquipment = [];
  String? scannedId;
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

  String _clean(String value) {
    return value.trim().replaceAll("\n", "").replaceAll(" ", "").replaceAll("-", "").toUpperCase();
  }

  void openChecklistPage() {
    if (item != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SmokeDetectorChecklistPage(selectedEquipment: item)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => GuidedCaptureWizardPage(
        selectedEquipment: item,
        equipmentImage: 'assets/smoke_detector.png',
        nextScreen: SmokeDetectorChecklistPage(selectedEquipment: item),
      )));
    }
  }

  Future<void> _submitInspection() async {
    if (item == null) return;
    await LocalDB.saveSingleModuleRecord(
      moduleCode: "smoke_detector",
      recordType: "equipment",
      item: item!,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Smoke Detector Inspection Saved Locally")));
  }

  void onDetect(BarcodeCapture capture) {
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;
    final cleaned = _clean(raw);
    setState(() {
      showScanner = false;
      idController.text = cleaned;
      scannedId = cleaned;
    });
    fetchDetails(cleaned);
  }

  Future<void> fetchDetails(String input) async {
    final id = _clean(input);
    setState(() {
      loading = true;
      error = null;
      showSearch = false;
      filteredEquipment = [];
    });

    try {
      Map<String, dynamic>? data;
      try {
        data = allEquipment.firstWhere((e) => (e["sos_code"] ?? e["equipment_id"] ?? e["id"])?.toString().toLowerCase() == id.toLowerCase());
      } catch (_) {
        data = await api.getEquipmentByQuery(id);
      }
      if (data == null) {
        setState(() {
          loading = false;
          error = "No smoke detector found for this ID";
          showSearch = true;
        });
        return;
      }
      setState(() {
        item = data;
        scannedId = id;
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

  void editAllFields() {
    if (item == null) return;
    final controllers = <String, TextEditingController>{};
    item!.forEach((key, value) => controllers[key] = TextEditingController(text: value?.toString() ?? ""));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Details"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              children: controllers.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: TextField(controller: e.value, decoration: InputDecoration(labelText: e.key.replaceAll("_", " ").toUpperCase(), border: const OutlineInputBorder())),
              )).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              controllers.forEach((key, controller) => item![key] = controller.text);
              await LocalDB.saveSingleModuleRecord(moduleCode: "smoke_detector", recordType: "equipment", item: item!);
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
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
            boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
            border: Border.all(color: Colors.blue.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: Colors.blue.shade800, borderRadius: BorderRadius.circular(12)),
                    child: Text(sosId.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                  ),
                  const Icon(Icons.smoke_free, color: Colors.blue, size: 28),
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
            ],
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text("Detector Inspection"),
        backgroundColor: Colors.blue.shade800,
        actions: [
          if (item != null) IconButton(icon: const Icon(Icons.edit), onPressed: editAllFields),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() { item = null; scannedId = null; idController.clear(); error = null; showSearch = true; filteredEquipment = []; })),
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: [
            if (showSearch)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                child: Column(
                  children: [
                    TextField(
                      controller: idController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: "Enter SOS ID (e.g. SOS-SMK-01)",
                        prefixIcon: const Icon(Icons.search, color: Colors.blue),
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
                            title: Text(e["id"]?.toString() ?? "-", style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(e["location_name"]?.toString() ?? "General Area"),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: () {
                              idController.text = e["id"].toString();
                              fetchDetails(e["id"].toString());
                            },
                          );
                        },
                      ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: () => fetchDetails(idController.text),
                            child: const Text("FETCH DETAILS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: Icon(Icons.qr_code_scanner, color: Colors.blue.shade800, size: 32),
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
                height: 200,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.blue, width: 2)),
                child: ClipRRect(borderRadius: BorderRadius.circular(18), child: MobileScanner(onDetect: onDetect)),
              ),
            if (loading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
            if (error != null) Center(child: Padding(padding: EdgeInsets.all(20), child: Text(error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))),
            if (item != null) buildDetails()
            else if (!loading && error == null)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search, size: 80, color: Colors.grey), Text("Enter SOS ID to begin inspection", style: TextStyle(color: Colors.grey))]))),
          ],
        ),
      ),
      bottomNavigationBar: item == null ? null : Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                icon: const Icon(Icons.checklist_rtl, color: Colors.white),
                label: const Text("CHECKLIST", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                onPressed: openChecklistPage,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                icon: const Icon(Icons.cloud_done, color: Colors.white),
                label: const Text("SUBMIT", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                onPressed: _submitInspection,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
