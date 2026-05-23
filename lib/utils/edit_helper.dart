import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/apiservice.dart';
import '../local_db.dart';

class EditHelper {
  static void editDetails({
    required BuildContext context,
    required Map<String, dynamic> item,
    required String moduleCode,
    required String equipmentId,
    required VoidCallback onSaved,
  }) {
    final box = Hive.box('inspectionBox');
    final String role = box.get('role', defaultValue: 'user').toString().toLowerCase().trim();

    final controllers = <String, TextEditingController>{};
    item.forEach((key, value) {
      controllers[key] = TextEditingController(text: value?.toString() ?? "");
    });

    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          role == 'supervisor' || role == 'admin' || role == 'superadmin'
              ? "Edit Details (Override)"
              : "Propose Equipment Updates",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (role != 'supervisor' && role != 'admin' && role != 'superadmin') ...[
                  TextField(
                    controller: remarksController,
                    decoration: InputDecoration(
                      labelText: "Remarks / Reason (Required)",
                      labelStyle: const TextStyle(fontSize: 13, color: Colors.red),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.comment_rounded, color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Divider(),
                  const SizedBox(height: 10),
                ],
                ...controllers.entries.where((e) => !e.key.contains("id")).map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: TextField(
                      controller: e.value,
                      decoration: InputDecoration(
                        labelText: e.key.toUpperCase().replaceAll('_', ' '),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (role == 'supervisor' || role == 'admin' || role == 'superadmin') {
                // Direct edit override flow
                controllers.forEach((key, controller) {
                  item[key] = controller.text;
                });
                await LocalDB.saveSingleModuleRecord(
                  moduleCode: moduleCode,
                  recordType: "equipment",
                  item: item,
                );
                onSaved();
                if (c.mounted) Navigator.pop(c);
                if (c.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Updated successfully ✅")),
                  );
                }
              } else {
                // Propose changes flow
                final proposed = <String, dynamic>{};
                controllers.forEach((key, controller) {
                  final originalVal = item[key]?.toString() ?? '';
                  final newVal = controller.text.trim();
                  if (originalVal != newVal) {
                    proposed[key] = newVal;
                  }
                });

                if (remarksController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Remarks are required to submit an update request")),
                  );
                  return;
                }

                proposed['remarks'] = remarksController.text.trim();

                if (c.mounted) Navigator.pop(c);

                final result = await ApiService.createEquipmentUpdateRequest(equipmentId, proposed);

                if (result != null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.green,
                        content: Text("Update request submitted for supervisor approval! ✅"),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.red,
                        content: Text("Failed to submit update request. Please try again."),
                      ),
                    );
                  }
                }
              }
            },
            child: Text(
              role == 'supervisor' || role == 'admin' || role == 'superadmin'
                  ? "Save"
                  : "Submit Proposal",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
