import 'package:flutter/services.dart';
import 'package:fire_new/utils/upper_case_text_formatter.dart';
import 'package:fire_new/services/apiservice.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'checklist.dart';
import 'guided_capture_wizard.dart';
import 'local_db.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/equipment_history_page.dart';
import 'package:fire_new/utils/map_flatten.dart';
import 'package:fire_new/services/location_service.dart';

class InspectionPage extends StatefulWidget {
  final String? preScannedId;
  const InspectionPage({super.key, this.preScannedId});

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
  bool _geofenceChecking = false;

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
    var list = await LocalDB.getAllExtinguishers();
    if (list.isEmpty) {
      try {
        await ApiService.syncAllExtinguishersToLocal();
        list = await LocalDB.getAllExtinguishers();
      } catch (_) {}
    }
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
            equipmentImage: 'assets/extinguisher.webp',
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
    double? lat;
    double? lng;
    if (item != null) {
      if (item!.containsKey("geofence") && item!["geofence"] is Map) {
        final gf = item!["geofence"] as Map;
        lat = double.tryParse((gf["stored_latitude"] ?? "").toString());
        lng = double.tryParse((gf["stored_longitude"] ?? "").toString());
      } else {
        lat = double.tryParse((item!["latitude"] ?? item!["lat"] ?? item!["stored_latitude"] ?? "").toString());
        lng = double.tryParse((item!["longitude"] ?? item!["lng"] ?? item!["stored_longitude"] ?? "").toString());
      }
    }
    // Fallback if no item selected or coordinates not configured
    lat ??= 17.5021988;
    lng ??= 78.3530868;

    final Uri uri = Uri.parse("geo:$lat,$lng?q=$lat,$lng");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng"));
    }
  }

  Future<bool> _checkGeofenceAndProceed(String sosCode) async {
    if (_geofenceChecking) return false;
    _geofenceChecking = true;
    try {
      final proceed = await LocationService.checkGeofenceAndShowDialog(
        context: context,
        sosCode: sosCode,
      );
      _geofenceChecking = false;
      return proceed;
    } catch (_) {
      _geofenceChecking = false;
      return true; // error fallback - allow through
    }
  }



  Future<void> _onScanDetected(String raw) async {
    if (loading || item != null) return;
    final cleanedId = _clean(raw);
    final canProceed = await _checkGeofenceAndProceed(cleanedId);
    if (!canProceed || !mounted) return;
    setState(() {
      showScanner = false;
      idController.text = cleanedId;
    });
    fetchDetails(raw);
  }

  Future<void> _onFetchTapped(String input) async {
    fetchDetails(input);
  }

  void onDetect(BarcodeCapture capture) {
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;
    _onScanDetected(raw);
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

    // Validate module code
    try {
      String? foundModule;
      final localM = await LocalDB.findEquipmentModuleAndData(input);
      if (localM != null) {
        foundModule = localM['module_code']?.toString();
      }
      if (foundModule == null) {
        final apiM = await ApiService.searchAny(input);
        if (apiM != null) {
          foundModule = apiM['module_code']?.toString() ?? 'fire_extinguisher';
        }
      }
      if (foundModule != null && foundModule != "fire_extinguisher") {
        setState(() {
          loading = false;
          error = "This is not Fire Extinguisher equipment";
          showSearch = true;
        });
        return;
      }
    } catch (_) {}

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
    
    final box = Hive.box('inspectionBox');
    final String role = box.get('role', defaultValue: 'user').toString().toLowerCase().trim();
    
    final controllers = <String, TextEditingController>{};
    item!.forEach((key, value) {
      controllers[key] = TextEditingController(text: value?.toString() ?? '');
    });

    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          role == 'supervisor' || role == 'admin' || role == 'superadmin'
              ? "Edit details (Override)"
              : "Propose Equipment Updates",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (role != 'supervisor' && role != 'admin' && role != 'superadmin') ...[
                  TextField(
                    controller: remarksController,
                    decoration: InputDecoration(
                      labelText: "Remarks / Reason (Required)",
                      labelStyle: const TextStyle(fontSize: 13, color: Colors.red),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.comment_rounded, color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Divider(),
                  const SizedBox(height: 10),
                ],
                ...controllers.entries.map((e) {
                  final isCoreId = e.key == 'id' || e.key == 'sos_code' || e.key == 'serial_number';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: TextField(
                      controller: e.value,
                      enabled: !isCoreId,
                      decoration: InputDecoration(
                        labelText: e.key.toUpperCase().replaceAll('_', ' '),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (role == 'supervisor' || role == 'admin' || role == 'superadmin') {
                controllers.forEach((key, controller) {
                  item![key] = controller.text;
                });
                await LocalDB.insert(scannedId!, item!);
                setState(() {});
                Navigator.pop(context);
                await saveData();
              } else {
                final proposed = <String, dynamic>{};
                controllers.forEach((key, controller) {
                  final originalVal = item![key]?.toString() ?? '';
                  final newVal = controller.text.trim();
                  if (originalVal != newVal) {
                    proposed[key] = newVal;
                  }
                });

                if (remarksController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Remarks are required to submit an update request")),
                  );
                  return;
                }

                proposed['remarks'] = remarksController.text.trim();

                setState(() => loading = true);
                Navigator.pop(context);

                final result = await ApiService.createEquipmentUpdateRequest(scannedId!, proposed);
                setState(() => loading = false);

                if (result != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.green,
                      content: Text("Update request submitted for supervisor approval! ✅"),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.red,
                      content: Text("Failed to submit update request. Please try again."),
                    ),
                  );
                }
              }
            },
            child: Text(
              role == 'supervisor' || role == 'admin' || role == 'superadmin'
                  ? "Save"
                  : "Submit Proposal",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
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
          if (item != null)
            IconButton(
              icon: const Icon(Icons.timeline_rounded, color: Colors.white),
              onPressed: () {
                final id = scannedId ?? item!['sos_code'] ?? item!['id'] ?? '';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EquipmentHistoryPage(
                      equipmentId: id.toString(),
                    ),
                  ),
                );
              },
            ),
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
                        _onScanDetected(c.barcodes.first.rawValue ?? "");
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
                        onPressed: () => _onFetchTapped(idController.text),
                        child: const Text("FETCH DETAILS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    if (suggestions.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: suggestions.length,
                        itemBuilder: (c, i) => Material(color: Colors.transparent, child: ListTile(
                          dense: true,
                          title: Text(suggestions[i]["sos_code"] ?? suggestions[i]["equipment_id"] ?? suggestions[i]["id"] ?? suggestions[i]["serial_number"] ?? "-"),
                          subtitle: Text(suggestions[i]["location_name"] ?? "-", style: const TextStyle(fontSize: 10)),
                          onTap: () {
                            idController.text = suggestions[i]["sos_code"] ?? suggestions[i]["equipment_id"] ?? suggestions[i]["id"] ?? suggestions[i]["serial_number"] ?? "";
                            _onFetchTapped(idController.text);
                          },
                        )),
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
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16)),
          icon: const Icon(Icons.list, color: Colors.white),
          label: const Text("Open Checklist", style: TextStyle(fontSize: 18, color: Colors.white)),
          onPressed: openChecklistPage,
        ),
      ),
    );
  }
}