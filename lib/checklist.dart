import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/apiservice.dart';

class ChecklistPage extends StatefulWidget {
  const ChecklistPage({super.key});

  @override
  State<ChecklistPage> createState() => _FireChecklistPageState();
}

class _FireChecklistPageState extends State<ChecklistPage> {
  List<Map<String, dynamic>> checklist = [];
  bool loading = true;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    fetchChecklist();
    syncIfPending();
  }

  // ================= FETCH =================
  Future<void> fetchChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    String? localData = prefs.getString("checklist");

    if (localData != null) {
      List decoded = jsonDecode(localData);
      setState(() {
        checklist = List<Map<String, dynamic>>.from(decoded);
        loading = false;
      });
      return;
    }

    try {
      final data = await ApiService.getFireChecklist();
      await prefs.setString("checklist", jsonEncode(data));

      setState(() {
        checklist = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        checklist = [];
        loading = false;
      });
    }
  }

  // ================= UPDATE =================
  Future<void> updateChecklist(List<Map<String, dynamic>> updatedList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("checklist", jsonEncode(updatedList));

    try {
      bool success = await ApiService.updateFireChecklist(updatedList);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Saved + Synced ✅")),
        );
      } else {
        throw Exception();
      }
    } catch (e) {
      await prefs.setBool("pendingSync", true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saved Offline ⚠️")),
      );
    }
  }

  Future<void> syncIfPending() async {
    final prefs = await SharedPreferences.getInstance();
    bool pending = prefs.getBool("pendingSync") ?? false;

    if (!pending) return;

    String? data = prefs.getString("checklist");

    if (data != null) {
      try {
        List<Map<String, dynamic>> decoded =
        List<Map<String, dynamic>>.from(jsonDecode(data));

        bool success = await ApiService.updateFireChecklist(decoded);

        if (success) {
          await prefs.setBool("pendingSync", false);
        }
      } catch (_) {}
    }
  }

  // ================= SUBMIT =================
  void submitChecklist() {
    List wrongItems =
    checklist.where((item) => item["no"] == true).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Submission"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: wrongItems.isEmpty
                ? [const Text("All items are correct ✅")]
                : [
              const Text(
                "Items marked NO ❌:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...wrongItems.map((e) => Text("• ${e["item"]}")),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await updateChecklist(checklist);
                setState(() => isEditing = false);
              },
              child: const Text("Submit"),
            )
          ],
        );
      },
    );
  }

  // ================= TOGGLE BUTTON =================
  Widget optionButton({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: isEditing ? onTap : null,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // ================= ROW =================
  Widget buildRow(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ITEM (WRAPS TEXT)
          Expanded(
            flex: 4,
            child: Text(
              item["item"] ?? "",
              style: const TextStyle(fontSize: 14),
              softWrap: true,
            ),
          ),

          const SizedBox(width: 10),

          // YES / NO / NA
          Expanded(
            flex: 6,
            child: Row(
              children: [
                optionButton(
                  label: "YES",
                  selected: item["yes"] == true,
                  color: Colors.green,
                  onTap: () {
                    setState(() {
                      item["yes"] = true;
                      item["no"] = false;
                      item["na"] = false;
                    });
                  },
                ),
                optionButton(
                  label: "NO",
                  selected: item["no"] == true,
                  color: Colors.red,
                  onTap: () {
                    setState(() {
                      item["no"] = true;
                      item["yes"] = false;
                      item["na"] = false;
                    });
                  },
                ),
                optionButton(
                  label: "NA",
                  selected: item["na"] == true,
                  color: Colors.orange,
                  onTap: () {
                    setState(() {
                      item["na"] = true;
                      item["yes"] = false;
                      item["no"] = false;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text(
          "EXTINGUISHER CHECKLIST",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.red),
            onPressed: () => setState(() => isEditing = true),
          )
        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              itemCount: checklist.length,
              itemBuilder: (context, index) {
                return buildRow(checklist[index], index);
              },
            ),
          ),

          if (isEditing)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: submitChecklist,
                child: const Text("SUBMIT"),
              ),
            ),
        ],
      ),
    );
  }
}