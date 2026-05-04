import 'package:flutter/material.dart';

import '../local_db.dart';
import 'services/hydrant_api_service.dart';

class HydrantChecklistPage extends StatefulWidget {
  const HydrantChecklistPage({super.key});

  @override
  State<HydrantChecklistPage> createState() => _HydrantChecklistPageState();
}

class _HydrantChecklistPageState extends State<HydrantChecklistPage> {
  final api = HydrantApiService();
  final TextEditingController hydrantIdController = TextEditingController();
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
      checklist = items.isNotEmpty
          ? items
          : [
              {"id": null, "item_text": "Hydrant body is visible and accessible"},
              {"id": null, "item_text": "Landing valve is operating smoothly"},
              {"id": null, "item_text": "Pressure gauge is readable and within safe range"},
              {"id": null, "item_text": "Hose box is sealed and clean"},
              {"id": null, "item_text": "Branch pipe and nozzle are available"},
            ];
      isLoading = false;
    });
  }

  @override
  void dispose() {
    hydrantIdController.dispose();
    inspectorController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  Future<void> _saveOffline() async {
    final hydrantId = hydrantIdController.text.trim();
    final inspector = inspectorController.text.trim();
    if (hydrantId.isEmpty || inspector.isEmpty) return;

    final payloadAnswers = <Map<String, dynamic>>[];
    for (var i = 0; i < checklist.length; i++) {
      final answer = answers[i];
      final itemId = checklist[i]["id"];
      if (answer == null || itemId == null) continue;
      payloadAnswers.add({
        "checklist_item_id": itemId,
        "answer": answer == "YES"
            ? "true"
            : answer == "NO"
                ? "false"
                : "na",
        "remarks": "",
      });
    }

    if (payloadAnswers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select checklist answers first.")),
      );
      return;
    }

    setState(() => isSaving = true);
    await LocalDB.queueModuleInspection(
      eventId: "hydrant-${DateTime.now().millisecondsSinceEpoch}",
      moduleCode: HydrantApiService.moduleCode,
      equipmentId: hydrantId,
      payload: {
        "inspector_name": inspector,
        "remarks": remarksController.text.trim(),
        "answers": payloadAnswers,
      },
    );
    if (!mounted) return;
    setState(() => isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Hydrant checklist saved in SQLite.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Hydrant Checklist"),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                TextField(
                  controller: hydrantIdController,
                  decoration: const InputDecoration(
                    labelText: "Hydrant SOS ID",
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
                const SizedBox(height: 10),
                TextField(
                  controller: remarksController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Remarks",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: checklist.length,
              itemBuilder: (context, index) {
                final item = checklist[index];
                final answer = answers[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (item["item_text"] ?? "").toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
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
            padding: const EdgeInsets.all(14),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
                  : const Text("SAVE CHECKLIST"),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
