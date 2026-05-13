import 'package:flutter/material.dart';
import '../local_db.dart';
import 'services/fire_trolley_api_service.dart';

class FireTrolleyChecklistPage extends StatefulWidget {
  const FireTrolleyChecklistPage({super.key});

  @override
  State<FireTrolleyChecklistPage> createState() => _FireTrolleyChecklistPageState();
}

class _FireTrolleyChecklistPageState extends State<FireTrolleyChecklistPage> {
  final api = FireTrolleyApiService();
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
  }

  Future<void> _loadChecklist() async {
    final items = await api.getChecklist();
    if (!mounted) return;
    setState(() {
      checklist = items.isNotEmpty ? items : [
        {"id": 1, "item_text": "All extinguishers present on trolley?"},
        {"id": 2, "item_text": "Wheels and handle in good condition?"},
        {"id": 3, "item_text": "Fire blanket and sand bucket checked?"},
        {"id": 4, "item_text": "Locking mechanism functional?"},
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
      payloadAnswers.add({
        "checklist_item_id": itemId,
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
      eventId: "trolley-${DateTime.now().millisecondsSinceEpoch}",
      moduleCode: FireTrolleyApiService.moduleCode,
      equipmentId: id,
      payload: {
        "inspector_name": inspector,
        "remarks": remarksController.text.trim(),
        "answers": payloadAnswers,
      },
    );
    if (!mounted) return;
    setState(() => isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fire Trolley checklist saved locally.")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE65100),
        title: const Text("Fire Trolley Checklist", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: [
                TextField(controller: equipmentIdController, decoration: const InputDecoration(labelText: "Trolley SOS ID", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: inspectorController, decoration: const InputDecoration(labelText: "Inspector Name", border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: remarksController, decoration: const InputDecoration(labelText: "Remarks", border: OutlineInputBorder())),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
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
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: isSaving ? null : _saveOffline,
              child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE TO SYNC QUEUE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
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
