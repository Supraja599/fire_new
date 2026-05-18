import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'checklist.dart';
import 'guided_capture_wizard.dart';
import 'services/apiservice.dart';
import 'local_db.dart';

class InspectionPage extends StatefulWidget {
  const InspectionPage({super.key});

  @override
  State<InspectionPage> createState() => _InspectionPageState();
}

class _InspectionPageState extends State<InspectionPage> {
  final TextEditingController idController = TextEditingController();

  String? scannedId;
  Map<String, dynamic>? item;
  bool loading = false;
  String? error;
  bool showScanner = true;
  bool showSearch = false;

  List<Map<String, dynamic>> allEquipment = [];
  List<Map<String, dynamic>> suggestions = [];

  @override
  void initState() {
    super.initState();
    _loadAllEquipment();
  }

  Future<void> _loadAllEquipment() async {
    final list = await LocalDB.getAllEquipmentGlobal();
    setState(() => allEquipment = list);
  }

  String _clean(String value) {
    return value.trim().replaceAll(" ", "").replaceAll("-", "").toUpperCase();
  }

  void _onSearchChanged(String val) {
    if (val.isEmpty) {
      setState(() => suggestions = []);
      return;
    }
    final cleaned = _clean(val);
    
    final results = allEquipment.where((e) {
      final id = _clean((e["sos_code"] ?? e["serial_number"] ?? e["id"] ?? "").toString());
      return id.contains(cleaned);
    }).take(5).toList();
    
    setState(() => suggestions = results);

    final exactMatch = allEquipment.firstWhere(
      (e) => _clean((e["sos_code"] ?? e["serial_number"] ?? e["id"] ?? "").toString()) == cleaned,
      orElse: () => <String, dynamic>{},
    );
    
    if (exactMatch.isNotEmpty) {
      fetchDetails(val);
    }
  }

  void openChecklistPage() {
    if (item != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChecklistPage(
            equipmentId: scannedId,
            selectedEquipment: item,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GuidedCaptureWizardPage(
            equipmentId: scannedId,
            selectedEquipment: item,
            equipmentImage: 'assets/extinguisher.png',
            nextScreen: ChecklistPage(
              equipmentId: scannedId,
              selectedEquipment: item,
            ),
          ),
        ),
      );
    }
  }

  Future<void> openNavigation() async {
    const double lat = 17.5064803;
    const double lng = 78.3554442;
    final Uri uri = Uri.parse("geo:$lat,$lng?q=$lat,$lng");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng"));
    }
  }

  void onDetect(BarcodeCapture capture) {
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;
    setState(() {
      showScanner = false;
      idController.text = _clean(raw);
    });
    fetchDetails(raw);
  }

  Future<void> fetchDetails(String input) async {
    final id = _clean(input);
    if (id.isEmpty) return;

    setState(() {
      loading = true;
      error = null;
      showSearch = false;
      suggestions = [];
    });

    try {
      final localData = await LocalDB.get(id);
      if (localData != null) {
        setState(() {
          item = localData;
          scannedId = id;
          loading = false;
        });
        return;
      }

      final data = await ApiService.searchAny(id);
      if (data == null) {
        setState(() {
          loading = false;
          error = "No data found";
          showSearch = true;
        });
        return;
      }
      await LocalDB.insert(id, data);
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

  Future<void> saveData() async {
    if (item == null) return;
    setState(() => loading = true);
    final success = await ApiService.insertVersion(item!);
    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? "Saved Successfully ✅" : "Saved Locally")));
  }

  void editAllFields() {
    if (item == null) return;
    final controllers = <String, TextEditingController>{};
    item!.forEach((key, value) {
      controllers[key] = TextEditingController(text: value.toString());
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Details"),
        content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(child: Column(children: controllers.entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: TextField(controller: e.value, decoration: InputDecoration(labelText: e.key, border: const OutlineInputBorder())))).toList()))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () async { controllers.forEach((key, controller) { item![key] = controller.text; }); await LocalDB.insert(scannedId!, item!); setState(() {}); Navigator.pop(context); await saveData(); }, child: const Text("Save")),
        ],
      ),
    );
  }

  Widget buildTable() {
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
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)), child: const Row(children: [Expanded(flex: 4, child: Text("FIELD", style: TextStyle(fontWeight: FontWeight.bold))), Expanded(flex: 6, child: Text("VALUE", style: TextStyle(fontWeight: FontWeight.bold)))])),
        const SizedBox(height: 10),
        ...displayFields.entries.map((e) => Container(margin: const EdgeInsets.symmetric(vertical: 5), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: Row(children: [Expanded(flex: 4, child: Text(e.key.replaceAll("_", " ").toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey))), Expanded(flex: 6, child: Text(e.value, style: const TextStyle(fontSize: 13)))]))),
        const SizedBox(height: 100),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text("Inspection System"),
        backgroundColor: Colors.red,
        actions: [
          if (item != null) IconButton(icon: const Icon(Icons.edit), onPressed: editAllFields),
          IconButton(icon: const Icon(Icons.save), onPressed: saveData),
          IconButton(icon: const Icon(Icons.navigation), onPressed: openNavigation),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() { item = null; scannedId = null; idController.clear(); error = null; showSearch = true; suggestions = []; })),
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
                    if (suggestions.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: suggestions.length,
                        itemBuilder: (c, i) => ListTile(
                          dense: true,
                          title: Text(suggestions[i]["sos_code"] ?? suggestions[i]["equipment_id"] ?? suggestions[i]["id"] ?? suggestions[i]["serial_number"] ?? "-"),
                          subtitle: Text(suggestions[i]["location_name"] ?? "-", style: const TextStyle(fontSize: 10)),
                          onTap: () {
                            idController.text = suggestions[i]["sos_code"] ?? suggestions[i]["equipment_id"] ?? suggestions[i]["id"] ?? suggestions[i]["serial_number"] ?? "";
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
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16)),
          icon: const Icon(Icons.list, color: Colors.white),
          label: const Text("Open Checklist", style: TextStyle(fontSize: 18, color: Colors.white)),
          onPressed: openChecklistPage,
        ),
      ),
    );
  }
}