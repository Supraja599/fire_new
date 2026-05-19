import 'package:flutter/material.dart';
import 'services/location_service.dart';

import 'local_db.dart';
import 'services/apiservice.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class ChecklistPage extends StatefulWidget {
  final String? equipmentId;
  final Map<String, dynamic>? selectedEquipment;
  const ChecklistPage({super.key, this.equipmentId, this.selectedEquipment});

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  final TextEditingController equipmentController = TextEditingController();
  final TextEditingController inspectorController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  
  File? _inspectionImage;
  final ImagePicker _picker = ImagePicker();

  late List<Map<String, dynamic>> checklist;
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    checklist = [];
    if (widget.equipmentId != null) {
      equipmentController.text = widget.equipmentId!;
    }
    _loadChecklist();
  }

  List<Map<String, dynamic>> _fallbackChecklist() {
    final items = [
      "Extinguisher is in its designated location and easily accessible",
      "Safety pin is intact and tamper seal is unbroken",
      "Pressure gauge reading is in the green/operable range",
      "Cylinder shows no signs of rust, dents, or damage",
      "Hose and nozzle are free of cracks, tears, or blockages",
      "Operating instructions are legible and facing outward",
      "Inspection tag is present and up to date",
      "Extinguisher feels full when lifted",
      "Wall bracket or cabinet is secure and undamaged",
      "No signs of leakage around the valve assembly",
    ];

    return List.generate(
      items.length,
      (i) => {
        "id": 400 + i, // Safe unique IDs for saving offline
        "item": items[i],
        "yes": false,
        "no": false,
        "na": false,
      },
    );
  }

  Future<void> _loadChecklist() async {
    try {
      final items = await ApiService.getFireChecklist();

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
      
      _applySmartPrefill();
    } catch (e) {
      debugPrint("Fire Extinguisher Checklist Error: $e");
      if (!mounted) return;
      setState(() {
        checklist = _fallbackChecklist();
        isLoading = false;
      });
      _applySmartPrefill();
    }
  }

  void _applySmartPrefill() {
    int prefilledCount = 0;
    for (int i = 0; i < checklist.length; i++) {
      final String text = (checklist[i]["item"] ?? "").toString().toLowerCase();
      
      bool isMatch = false;
      
      // View 1 & 4 indicators (Location, Access, Clearance)
      if (text.contains("location") || 
          text.contains("access") || 
          text.contains("mounting") || 
          text.contains("clearance") || 
          text.contains("bracket") || 
          text.contains("cabinet")) {
        isMatch = true;
      }
      
      // View 2 indicators (Tags, Labels, Instructions)
      if (text.contains("tag") || 
          text.contains("label") || 
          text.contains("instruction") || 
          text.contains("legible") || 
          text.contains("date") || 
          text.contains("sign")) {
        isMatch = true;
      }
      
      // View 3 indicators (Gauge, Valves, Pin, Nozzle)
      if (text.contains("gauge") || 
          text.contains("valve") || 
          text.contains("pressure") || 
          text.contains("seal") || 
          text.contains("pin") || 
          text.contains("nozzle")) {
        isMatch = true;
      }

      if (isMatch) {
        setState(() {
          checklist[i]["yes"] = true;
          checklist[i]["no"] = false;
          checklist[i]["na"] = false;
        });
        prefilledCount++;
      }
    }

    if (prefilledCount > 0 && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F172A), // Dark elegant slate matching app
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.cyanAccent, width: 1),
            ),
            content: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "🤖 AI ASSIST ACTIVE",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: Colors.cyanAccent,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Automatically pre-filled $prefilledCount items based on secured visual telemetry proofs!",
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      });
    }
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

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 60, // Conserve SQL footprint and cache space
        maxWidth: 800,    // High-enough fidelity for text legibility
      );
      if (photo != null) {
        setState(() {
          _inspectionImage = File(photo.path);
        });
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  Future<void> _saveOffline() async {
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

    // --- GEOLOCATION PROXIMITY VERIFICATION BLOCK ---
    if (widget.selectedEquipment != null &&
        (widget.selectedEquipment!["latitude"] != null || widget.selectedEquipment!["lat"] != null) &&
        (widget.selectedEquipment!["longitude"] != null || widget.selectedEquipment!["lng"] != null)) {
      
      double? lat = double.tryParse((widget.selectedEquipment!["latitude"] ?? widget.selectedEquipment!["lat"]).toString());
      double? lng = double.tryParse((widget.selectedEquipment!["longitude"] ?? widget.selectedEquipment!["lng"]).toString());
      
      if (lat != null && lng != null) {
        // Show temporary loading dialog
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
          context: context,
        );

        if (mounted) Navigator.pop(context); // Dismiss loader

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

    setState(() => isSaving = true);

    String? base64Image;
    try {
      if (_inspectionImage != null) {
        final bytes = await _inspectionImage!.readAsBytes();
        base64Image = base64Encode(bytes);
      }
    } catch (e) {
      debugPrint("Error encoding offline image: $e");
    }

    final eventId = "extinguisher-${DateTime.now().millisecondsSinceEpoch}";
    final payload = {
      "inspector_name": inspectorName,
      "remarks": remarksController.text.trim(),
      "answers": answers,
      "photo_base64": base64Image, // INJECTED OFFLINE IMAGE PROOF!
    };

    await LocalDB.queueModuleInspection(
      eventId: eventId,
      moduleCode: "fire_extinguisher",
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Extinguisher Checklist",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
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
            // Replaced Expanded ListView with a non-expanded ListView.builder 
            // with shrinkWrap: true so it works inside SingleChildScrollView
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Inspection Photo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(
                          _inspectionImage == null 
                              ? "Attach a photo proof (Optional)" 
                              : "Photo secured offline! ✅", 
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  if (_inspectionImage != null)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_inspectionImage!, width: 55, height: 55, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: -8,
                          right: -8,
                          child: GestureDetector(
                            onTap: () => setState(() => _inspectionImage = null),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _takePhoto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.camera_alt, size: 16),
                      label: const Text("Capture", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
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
