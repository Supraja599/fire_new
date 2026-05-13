import 'package:flutter/material.dart';

import 'local_db.dart';
import 'services/apiservice.dart';

class ChecklistPage extends StatefulWidget {
  final String? equipmentId;
  const ChecklistPage({super.key, this.equipmentId});

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
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
    } catch (e) {
      debugPrint("Fire Extinguisher Checklist Error: $e");
      if (!mounted) return;
      setState(() {
        checklist = _fallbackChecklist();
        isLoading = false;
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

    final eventId = "extinguisher-${DateTime.now().millisecondsSinceEpoch}";
    final payload = {
      "inspector_name": inspectorName,
      "remarks": remarksController.text.trim(),
      "answers": answers,
    };

    setState(() => isSaving = true);

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
        content: Text("Checklist saved in Hive and queued for sync ✅"),
      ),
    );
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
          "Extinguisher Checklist",
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
                      "SAVE OFFLINE TO HIVE",
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
