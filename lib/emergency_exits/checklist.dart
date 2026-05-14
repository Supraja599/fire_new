import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../local_db.dart';
import 'services/api_service.dart';

class EmergencyExitsChecklistPage extends StatefulWidget {
  final Map<String, dynamic>? selectedEquipment;
  const EmergencyExitsChecklistPage({super.key, this.selectedEquipment});
  @override
  State<EmergencyExitsChecklistPage> createState() => _EmergencyExitsChecklistPageState();
}

class _EmergencyExitsChecklistPageState extends State<EmergencyExitsChecklistPage> {
  final api = EmergencyExitsApiService();
  final remarksController = TextEditingController();
  List<Map<String, dynamic>> questions = [];
  Map<int, String> answers = {};
  bool isLoading = true;

  @override
  void dispose() {
    remarksController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    final list = await api.getChecklist();
    setState(() { questions = list; isLoading = false; });
  }

  Future<void> _saveInspection() async {
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

    setState(() => isLoading = true);
    
    final payload = {
      "answers": answers,
      "remarks": remarksController.text.trim(),
      "timestamp": DateTime.now().toIso8601String(),
    };

    // OFFLINE QUEUEING (SQLITE)
    await LocalDB.queueModuleInspection(
      eventId: "EXIT_${DateTime.now().millisecondsSinceEpoch}",
      moduleCode: EmergencyExitsApiService.moduleCode,
      equipmentId: "UNKNOWN", // In real app, pass current equipment ID
      payload: payload,
    );

    setState(() => isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("SAVED ✅"),
      ),
    );
    Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Safety Checklist"), backgroundColor: Colors.red),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        itemCount: questions.length,
        itemBuilder: (c, i) {
          final q = questions[i];
          return Card(
            margin: const EdgeInsets.all(10),
            child: Column(children: [
              ListTile(title: Text(q["question"] ?? "Question")),
              Row(children: [
                Radio<String>(value: "YES", groupValue: answers[i], onChanged: (v) => setState(() => answers[i] = v!)),
                const Text("YES"),
                Radio<String>(value: "NO", groupValue: answers[i], onChanged: (v) => setState(() => answers[i] = v!)),
                const Text("NO"),
              ]),
            ]),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: remarksController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Remarks (Optional)",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 18)),
                onPressed: _saveInspection,
                child: const Text("SUBMIT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
