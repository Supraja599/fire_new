import 'package:flutter/material.dart';
import '../local_db.dart';
import 'services/api_service.dart';

class EmergencyExitsChecklistPage extends StatefulWidget {
  const EmergencyExitsChecklistPage({super.key});
  @override
  State<EmergencyExitsChecklistPage> createState() => _EmergencyExitsChecklistPageState();
}

class _EmergencyExitsChecklistPageState extends State<EmergencyExitsChecklistPage> {
  final api = EmergencyExitsApiService();
  List<Map<String, dynamic>> questions = [];
  Map<int, String> answers = {};
  bool isLoading = true;

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
    setState(() => isLoading = true);
    
    final payload = {
      "answers": answers,
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Inspection saved locally (Offline Sync)"),
        backgroundColor: Colors.green,
      ));
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
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 18)),
          onPressed: _saveInspection,
          child: const Text("SAVE INSPECTION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
