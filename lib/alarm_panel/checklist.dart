import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../local_db.dart';
import 'services/alarm_panel_api_service.dart';

class AlarmPanelChecklistPage extends StatefulWidget {
  final Map<String, dynamic>? selectedEquipment;
  const AlarmPanelChecklistPage({super.key, this.selectedEquipment});

  @override
  State<AlarmPanelChecklistPage> createState() => _AlarmPanelChecklistPageState();
}

class _AlarmPanelChecklistPageState extends State<AlarmPanelChecklistPage> {
  final api = AlarmPanelApiService();
  final TextEditingController equipmentIdController = TextEditingController();
  final TextEditingController inspectorController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final Map<int, String> answers = {};
  List<Map<String, dynamic>> checklist = [];
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadChecklist();
    if (widget.selectedEquipment != null) {
      equipmentIdController.text = widget.selectedEquipment!["sos_code"]?.toString() ?? 
                               widget.selectedEquipment!["equipment_id"]?.toString() ?? 
                               widget.selectedEquipment!["id"]?.toString() ?? "";
    }
  }

  Future<void> _loadChecklist() async {
    final items = await api.getChecklist();
    if (!mounted) return;
    setState(() {
      checklist = items.isNotEmpty ? items : [
        {"id": 1, "item_text": "Panel visual inspection completed?"},
        {"id": 2, "item_text": "Back-up batteries checked?"},
        {"id": 3, "item_text": "Remote signal monitoring active?"},
        {"id": 4, "item_text": "Logbook entries updated?"},
      ];
      isLoading = false;
    });
  }

  @override
  void dispose() {
    equipmentIdController.dispose();
    inspectorController.dispose();
    remarksController.dispose();
    super.dispose();
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

    final id = equipmentIdController.text.trim();
    final inspector = inspectorController.text.trim();
    if (id.isEmpty || inspector.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter SOS ID and Inspector Name")));
      return;
    }

    final payloadAnswers = <Map<String, dynamic>>[];
    for (var i = 0; i < checklist.length; i++) {
      final answer = answers[i];
      final itemId = checklist[i]["id"];
      if (answer == null || itemId == null) continue;
      final itemText = checklist[i]["item_text"] ?? checklist[i]["item"] ?? checklist[i]["question"] ?? checklist[i]["question_text"] ?? checklist[i]["name"] ?? checklist[i]["title"] ?? checklist[i]["description"] ?? checklist[i]["text"] ?? checklist[i]["checklist_item"] ?? checklist[i]["content"] ?? "Unknown Question";
      payloadAnswers.add({
        "checklist_item_id": itemId,
        "item_text": itemText,
        "answer": answer == "YES" ? "true" : answer == "NO" ? "false" : "na",
        "remarks": "",
      });
    }

    if (payloadAnswers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select checklist answers first.")));
      return;
    }

    setState(() => isSaving = true);
    await LocalDB.queueModuleInspection(
      eventId: "alarm-${DateTime.now().millisecondsSinceEpoch}",
      moduleCode: AlarmPanelApiService.moduleCode,
      equipmentId: id,
      payload: {
        "inspector_name": inspector,
        "remarks": remarksController.text.trim(),
        "answers": payloadAnswers,
      },
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
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFFDECEA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD50000),
        title: const Text("Alarm Panel Checklist", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  TextField(controller: equipmentIdController, decoration: const InputDecoration(labelText: "Panel SOS ID", border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: inspectorController, decoration: const InputDecoration(labelText: "Inspector Name", border: OutlineInputBorder())),
  
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: checklist.length,
              itemBuilder: (context, index) {
                final item = checklist[index];
                final answer = answers[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item["item_text"] ?? item["item"] ?? item["question"] ?? item["question_text"] ?? item["name"] ?? item["title"] ?? item["description"] ?? item["text"] ?? item["checklist_item"] ?? item["content"] ?? "Unknown Question", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _choice(index, "YES", answer == "YES", Colors.green),
                          const SizedBox(width: 8),
                          _choice(index, "NO", answer == "NO", Colors.red),
                          const SizedBox(width: 8),
                          _choice(index, "NA", answer == "NA", Colors.orange),
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
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD50000), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: isSaving ? null : _saveOffline,
                child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("SUBMIT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choice(int index, String label, bool selected, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => answers[index] = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: selected ? color : Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.black, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }
}
