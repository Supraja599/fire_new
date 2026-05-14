import 'package:flutter/material.dart';
import '../services/location_service.dart';

import '../local_db.dart';
import 'services/apiservice.dart';

class HoseReelChecklistPage extends StatefulWidget {
  final Map<String, dynamic>? selectedEquipment;
  const HoseReelChecklistPage({super.key, this.selectedEquipment});

  @override
  State<HoseReelChecklistPage> createState() => _HoseReelChecklistPageState();
}

class _HoseReelChecklistPageState extends State<HoseReelChecklistPage> {
  final api = HoseReelApiService();
  final TextEditingController equipmentController = TextEditingController();
  final TextEditingController inspectorController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  late List<Map<String, dynamic>> checklist;
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    checklist = [];
    _loadChecklist();
  }

  List<Map<String, dynamic>> _fallbackChecklist() {
    final items = [
      "Hose reel cabinet and access area are clean and unobstructed",
      "Hose reel drum rotates smoothly and locks correctly",
      "Hose is free from cracks, cuts, and flattening",
      "Nozzle is present, secure, and free from leakage",
      "Valve opens and closes without resistance",
      "Water pressure is adequate during test",
      "Mounting bracket and fasteners are secure",
      "Identification tag and signage are visible",
      "Inspection label is updated with latest date",
      "Surrounding area is safe for emergency operation",
    ];

    return List.generate(
      items.length,
      (i) => {
        "id": 300 + i, // Safe unique fallback IDs
        "item": items[i],
        "yes": false,
        "no": false,
        "na": false,
      },
    );
  }

  Future<void> _loadChecklist() async {
    final items = await api.getChecklist();

    if (!mounted) return;

    setState(() {
      checklist = items.isNotEmpty
          ? items
              .map(
                (item) => {
                  "id": item["id"],
                  "item": item["item_text"] ?? item["item"] ?? item["question"] ?? item["question_text"] ?? item["name"] ?? item["title"] ?? item["description"] ?? item["text"] ?? item["checklist_item"] ?? item["content"] ?? "Unknown Question",
                  "yes": false,
                  "no": false,
                  "na": false,
                },
              )
              .toList()
          : _fallbackChecklist();
      isLoading = false;
    });
  }

  void _setValue(int index, String type) {
    setState(() {
      checklist[index]["yes"] = type == "YES";
      checklist[index]["no"] = type == "NO";
      checklist[index]["na"] = type == "NA";
    });
  }

  Color _statusColor(Map<String, dynamic> item) {
    if (item["yes"] == true) return Colors.green;
    if (item["no"] == true) return Colors.red;
    if (item["na"] == true) return Colors.orange;
    return Colors.grey;
  }

  String? _answerFor(Map<String, dynamic> item) {
    if (item["yes"] == true) return "true";
    if (item["no"] == true) return "false";
    if (item["na"] == true) return "na";
    return null;
  }

  Future<void> _saveOffline() async {
    // --- GEOLOCATION PROXIMITY VERIFICATION BLOCK ---
    if (widget.selectedEquipment != null &&
        (widget.selectedEquipment!["latitude"] != null || widget.selectedEquipment!["lat"] != null) &&
        (widget.selectedEquipment!["longitude"] != null || widget.selectedEquipment!["lng"] != null)) {
      
      double? lat = double.tryParse((widget.selectedEquipment!["latitude"] ?? widget.selectedEquipment!["lat"]).toString());
      double? lng = double.tryParse((widget.selectedEquipment!["longitude"] ?? widget.selectedEquipment!["lng"]).toString());
      
      if (lat != null && lng != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(color: Colors.red),
                SizedBox(width: 20),
                Text("Verifying physical presence..."),
              ],
            ),
          ),
        );

        final result = await LocationService.verifyProximity(
          targetLat: lat,
          targetLng: lng,
          maxAllowedDistanceMeters: 100.0,
        );

        if (mounted) Navigator.pop(context);

        if (!result.success) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text("Location Check Required"),
                content: Text(result.errorMessage ?? "Unknown Location Error"),
                actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
              ),
            );
          }
          return;
        }

        if (!result.withinRange) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (c) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: Colors.red),
                    SizedBox(width: 8),
                    Text("Action Restricted", style: TextStyle(color: Colors.red)),
                  ],
                ),
                content: Text("⚠️ Location Verification Failed!\n\nYou are ${result.distanceMeters?.toStringAsFixed(1)} meters away from the asset location.\n\nYou must stand within 100 meters of this equipment to perform inspection."),
                actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))],
              ),
            );
          }
          return;
        }
      }
    }
    // --- END OF VERIFICATION BLOCK ---

    final equipmentId = equipmentController.text.trim();
    final inspectorName = inspectorController.text.trim();

    if (equipmentId.isEmpty || inspectorName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter equipment code and inspector name first."),
        ),
      );
      return;
    }

    final answers = checklist
        .where((item) => item["id"] != null && _answerFor(item) != null)
        .map(
          (item) => {
            "checklist_item_id": item["id"],
            "answer": _answerFor(item),
            "remarks": "",
          },
        )
        .toList();

    if (answers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Select at least one checklist answer to save."),
        ),
      );
      return;
    }

    final eventId = "hose-${DateTime.now().millisecondsSinceEpoch}";
    final payload = {
      "inspector_name": inspectorName,
      "remarks": remarksController.text.trim(),
      "answers": answers,
    };

    setState(() => isSaving = true);

    await LocalDB.queueModuleInspection(
      eventId: eventId,
      moduleCode: HoseReelApiService.moduleCode,
      equipmentId: equipmentId,
      payload: payload,
    );

    if (!mounted) return;

    setState(() => isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("SAVED ✅"),
      ),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    equipmentController.dispose();
    inspectorController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Hose Reel Checklist",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: equipmentController,
                  decoration: const InputDecoration(
                    labelText: "Equipment SOS Code / ID",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: inspectorController,
                  decoration: const InputDecoration(
                    labelText: "Inspector Name",
                    border: OutlineInputBorder(),
                  ),
                ),

              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: checklist.length,
              itemBuilder: (context, index) {
                final item = checklist[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _statusColor(item).withOpacity(0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _statusColor(item),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item["item"],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _btn(index, "YES", Colors.green),
                          const SizedBox(width: 8),
                          _btn(index, "NO", Colors.red),
                          const SizedBox(width: 8),
                          _btn(index, "NA", Colors.orange),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
              ],
            ),
            child: TextField(
              controller: remarksController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Remarks (Optional)",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isSaving ? null : _saveOffline,
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "SUBMIT",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(int index, String label, Color color) {
    final item = checklist[index];

    bool selected = false;
    if (label == "YES") selected = item["yes"] == true;
    if (label == "NO") selected = item["no"] == true;
    if (label == "NA") selected = item["na"] == true;

    return Expanded(
      child: GestureDetector(
        onTap: () => _setValue(index, label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
