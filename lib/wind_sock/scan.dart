
import 'package:flutter/services.dart';
import 'package:fire_new/utils/upper_case_text_formatter.dart';
import 'package:fire_new/services/module_api_service.dart';
import '../utils/edit_helper.dart';
import '../screens/equipment_history_page.dart';
import 'package:flutter/material.dart';
import 'package:fire_new/guided_capture_wizard.dart';

import 'package:mobile_scanner/mobile_scanner.dart';
import '../local_db.dart';
import 'checklist.dart';
import 'package:fire_new/utils/map_flatten.dart';
class WindSockScanPage extends StatefulWidget {
  const WindSockScanPage({super.key});
  @override
  State<WindSockScanPage> createState() => _WindSockScanPageState();
}

class _WindSockScanPageState extends State<WindSockScanPage> {
  final TextEditingController idController = TextEditingController();
  final api = ModuleApiService.windSock;
  Map<String, dynamic>? item;
  bool loading = false;
  bool showScanner = true;
  bool isManualMode = false;
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
    setState(() { loading = true; suggestions = []; });
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
    EditHelper.editDetails(
      context: context,
      item: item!,
      moduleCode: ModuleApiService.windSock.moduleCode,
      equipmentId: (item!["sos_code"] ?? item!["equipment_id"] ?? item!["id"] ?? "").toString(),
      onSaved: () => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text("Inspection System"), backgroundColor: Colors.red, actions: [if (item != null) IconButton(icon: const Icon(Icons.edit), onPressed: _editDetails),
          if (item != null)
            IconButton(
              icon: const Icon(Icons.timeline_rounded, color: Colors.white),
              onPressed: () {
                final id = item!['sos_code'] ?? item!['id'] ?? item!['equipment_id'] ?? '';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EquipmentHistoryPage(
                      equipmentId: id.toString(),
                    ),
                  ),
                );
              },
            ), IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() { item = null; idController.clear(); suggestions = []; showScanner = true; isManualMode = false; }))]),
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
                        _fetchDetails(idController.text);
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
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        UpperCaseTextFormatter(),
                      ],
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
                        onPressed: () => _fetchDetails(idController.text),
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
                            _fetchDetails(idController.text);
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
                    ...buildDetailRows(item!),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          icon: const Icon(Icons.list, color: Colors.white),
          label: const Text("OPEN CHECKLIST", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: () {
            if (item != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => WindSockChecklistPage(selectedEquipment: item)));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => GuidedCaptureWizardPage(
                selectedEquipment: item,
                equipmentImage: 'assets/wind_sock.webp',
                nextScreen: WindSockChecklistPage(selectedEquipment: item),
              )));
            }
          },
        ),
      ),
    );
  }
}

