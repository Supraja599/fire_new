import 'package:flutter/material.dart';

import '../local_db.dart';
import 'services/sprinkler_api_service.dart';

class SprinklerChecklistPage extends StatefulWidget {
  const SprinklerChecklistPage({super.key});

  @override
  State<SprinklerChecklistPage> createState() => _SprinklerChecklistPageState();
}

class _SprinklerChecklistPageState extends State<SprinklerChecklistPage> {
  final api = SprinklerApiService();
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
      "Ensure all control valves are open, locked, sealed, and properly labeled",
      "Verify tamper switches and supervisory alarms are functional",
      "Ensure valve areas are accessible and well maintained",
      "Check pressure gauges are installed, readable, calibrated, and within limits",
      "Ensure sprinkler heads are clean, undamaged, correctly installed, and properly spaced",
      "Verify correct temperature rating and color coding of sprinkler heads",
      "Maintain minimum clearance and ensure no obstruction to spray pattern",
      "Keep spare sprinkler heads and wrench available",
      "Inspect piping for leaks, corrosion, damage, and unauthorized modifications",
      "Ensure proper pipe supports, spacing, and seismic bracing",
      "Verify pipelines are properly identified (fire line marking)",
      "Ensure proper slope in dry systems",
      "Test water flow and verify alarm activation and signal transmission",
      "Ensure alarms are audible, visible, and responsive",
      "Check flow switches and system integration",
      "Ensure adequate and reliable water supply with sufficient pressure and flow",
      "Verify fire water storage and dedicated supply system",
      "Ensure all supply valves are open and unobstructed",
      "Verify fire pump automatic operation, pressure performance, and regular testing",
      "Ensure adequate fuel/power supply and proper pump room conditions",
      "Check dry system components including air compressor, pressure, and alarms",
      "Verify antifreeze systems where applicable",
      "Inspect backflow preventer operation, leakage condition, and certification",
      "Ensure no unauthorized bypass connections",
      "Verify fire department connection accessibility, condition, and identification",
      "Conduct main drain test and compare pressure readings with previous records",
      "Ensure fire alarm panel operation, system integration, wiring, and backup power",
      "Verify hazard classification, sprinkler spacing, and system design compliance",
      "Ensure no changes affecting system performance (storage, occupancy, layout)",
      "Maintain all inspection, testing, maintenance records, and compliance certificates",
      "Ensure compliance with NFPA, ISO, BIS / NBC standards",
      "Ensure clear access, proper signage, and housekeeping around fire systems",
      "Record defects, recommend corrective actions, verify repairs",
    ];

    return items
        .map(
          (item) => {
            "id": null,
            "item": item,
            "yes": false,
            "no": false,
            "na": false,
          },
        )
        .toList();
  }

  Future<void> _loadChecklist() async {
    try {
      final items = await api.getChecklist();

      if (!mounted) return;

      if (items.isNotEmpty) {
        setState(() {
          checklist = items
              .map(
                (item) => {
                  "id": item["id"],
                  "item": item["item_text"] ?? "",
                  "yes": false,
                  "no": false,
                  "na": false,
                },
              )
              .toList();
          isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      checklist = _fallbackChecklist();
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

    final eventId = "sprinkler-${DateTime.now().millisecondsSinceEpoch}";
    final payload = {
      "inspector_name": inspectorName,
      "remarks": remarksController.text.trim(),
      "answers": answers,
    };

    setState(() => isSaving = true);

    await LocalDB.queueModuleInspection(
      eventId: eventId,
      moduleCode: SprinklerApiService.moduleCode,
      equipmentId: equipmentId,
      payload: payload,
    );

    if (!mounted) return;

    setState(() => isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Checklist saved in SQLite and queued for sync."),
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
          "Fire Sprinkler Checklist",
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
                      "SAVE OFFLINE TO SQLITE",
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
