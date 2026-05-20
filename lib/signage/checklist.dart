import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../local_db.dart';
import 'services/api_service.dart';

class SignageChecklistPage extends StatefulWidget {
  final Map<String, dynamic>? selectedEquipment;
  const SignageChecklistPage({super.key, this.selectedEquipment});
  @override
  State<SignageChecklistPage> createState() => _SignageChecklistPageState();
}

class _SignageChecklistPageState extends State<SignageChecklistPage> {
  final api = SignageApiService();
  final equipmentController = TextEditingController();
  final inspectorController = TextEditingController();
  final remarksController = TextEditingController();
  List<Map<String, dynamic>> questions = [];
  bool isLoading = true;

  @override
  void initState() { 
    super.initState(); 
    _load(); 
    if (widget.selectedEquipment != null) {
      equipmentController.text = widget.selectedEquipment!["sos_code"]?.toString() ?? 
                               widget.selectedEquipment!["equipment_id"]?.toString() ?? 
                               widget.selectedEquipment!["id"]?.toString() ?? "";
    }
  }

  Future<void> _load() async {
    try {
      final list = await api.getChecklist();
      if (mounted) {
        setState(() {
          questions = list.map((q) => {
            "id": q["id"],
            "item": q["item_text"] ?? q["item"] ?? q["question"] ?? q["question_text"] ?? q["name"] ?? q["title"] ?? q["description"] ?? q["text"] ?? q["checklist_item"] ?? q["content"] ?? "Unknown Question",
            "yes": false,
            "no": false,
            "na": false
          }).toList();
          if (questions.isEmpty) {
            questions = [{"id": 1, "item": "Is equipment accessible and in good condition?", "yes": false, "no": false, "na": false}];
          }
          isLoading = false;
        });
      }
    } catch (_) { if (mounted) setState(() => isLoading = false); }
  }

  void _save() async {
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

    final eq = equipmentController.text.trim();
    final ins = inspectorController.text.trim();
    if (eq.isEmpty || ins.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter ID and Name")));
      return;
    }
    final answers = questions.where((q) => q["yes"] || q["no"] || q["na"]).map((q) => {
      "checklist_item_id": q["id"],
      "item_text": q["item_text"] ?? q["item"] ?? q["question"] ?? q["question_text"] ?? q["name"] ?? q["title"] ?? q["description"] ?? q["text"] ?? q["checklist_item"] ?? q["content"] ?? "Unknown Question",
      "answer": q["yes"] ? "true" : q["no"] ? "false" : "na"
    }).toList();
    if (answers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Answer at least one question")));
      return;
    }
    await LocalDB.queueModuleInspection(
      eventId: "ev-$eq-${DateTime.now().millisecondsSinceEpoch}",
      moduleCode: SignageApiService.moduleCode,
      equipmentId: eq,
      payload: {"inspector_name": ins, "remarks": remarksController.text, "answers": answers}
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("SAVED ✅"),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(title: Text("Signage Checklist"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 1),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          TextField(controller: equipmentController, decoration: const InputDecoration(labelText: "Equipment ID (SOS Code)", border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: inspectorController, decoration: const InputDecoration(labelText: "Inspector Name", border: OutlineInputBorder())),
        ])),
        Expanded(child: ListView.builder(itemCount: questions.length, itemBuilder: (c, i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(questions[i]["item"], style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Row(children: [_b(i, "YES", Colors.green), const SizedBox(width: 8), _b(i, "NO", Colors.red), const SizedBox(width: 8), _b(i, "NA", Colors.orange)]),
          ]),
        ))),
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
        Container(width: double.infinity, padding: const EdgeInsets.all(12), child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: _save,
          child: const Text("SUBMIT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        )),
      ]),
    );
  }
  Widget _b(int i, String l, Color c) {
    bool s = (l == "YES" && questions[i]["yes"]) || (l == "NO" && questions[i]["no"]) || (l == "NA" && questions[i]["na"]);
    return Expanded(child: GestureDetector(
      onTap: () => setState(() { questions[i]["yes"] = l=="YES"; questions[i]["no"] = l=="NO"; questions[i]["na"] = l=="NA"; }),
      child: Container(padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: s ? c : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: Text(l, style: TextStyle(color: s ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12))),
    ));
  }
}

