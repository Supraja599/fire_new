import 'package:flutter/material.dart';
import '../local_db.dart';
import 'services/api_service.dart';

class EmergencyShowerChecklistPage extends StatefulWidget {
  const EmergencyShowerChecklistPage({super.key});
  @override
  State<EmergencyShowerChecklistPage> createState() => _EmergencyShowerChecklistPageState();
}

class _EmergencyShowerChecklistPageState extends State<EmergencyShowerChecklistPage> {
  final api = EmergencyShowerApiService();
  final equipmentController = TextEditingController();
  final inspectorController = TextEditingController();
  final remarksController = TextEditingController();
  List<Map<String, dynamic>> questions = [];
  bool isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

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
    final eq = equipmentController.text.trim();
    final ins = inspectorController.text.trim();
    if (eq.isEmpty || ins.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter ID and Name")));
      return;
    }
    final answers = questions.where((q) => q["yes"] || q["no"] || q["na"]).map((q) => {
      "checklist_item_id": q["id"],
      "answer": q["yes"] ? "true" : q["no"] ? "false" : "na"
    }).toList();
    if (answers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Answer at least one question")));
      return;
    }
    await LocalDB.queueModuleInspection(
      eventId: "ev-$eq-${DateTime.now().millisecondsSinceEpoch}",
      moduleCode: EmergencyShowerApiService.moduleCode,
      equipmentId: eq,
      payload: {"inspector_name": ins, "remarks": remarksController.text, "answers": answers}
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved Offline")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(title: Text("Emergency Shower Checklist"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 1),
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
        Container(width: double.infinity, padding: const EdgeInsets.all(12), child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: _save,
          child: const Text("SAVE INSPECTION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

