import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ChecklistPage extends StatefulWidget {
  const ChecklistPage({super.key});

  @override
  State<ChecklistPage> createState() => _FireChecklistPageState();
}

class _FireChecklistPageState extends State<ChecklistPage> {
  List<Map<String, dynamic>> checklist = [];
  bool loading = true;

  final String url =
      "https://script.google.com/macros/s/AKfycbwiT4HVTj-zlaJlpTHvfS6K6rPR-uDRXV32lU2sfpZs29A2aY-FD-P0jFjPBC_REKat/exec";

  @override
  void initState() {
    super.initState();
    fetchChecklist();
    syncIfPending();
  }

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
      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);

        List<Map<String, dynamic>> temp =
        List<Map<String, dynamic>>.from(data);

        await prefs.setString("checklist", jsonEncode(temp));

        setState(() {
          checklist = temp;
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        checklist = [];
        loading = false;
      });
    }
  }

  Future<void> updateChecklist(List<Map<String, dynamic>> updatedList) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("checklist", jsonEncode(updatedList));

    try {
      await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updatedList),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saved + Synced ✅")),
      );
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

    if (pending) {
      String? data = prefs.getString("checklist");

      if (data != null) {
        try {
          await http.post(
            Uri.parse(url),
            headers: {"Content-Type": "application/json"},
            body: data,
          );

          await prefs.setBool("pendingSync", false);
        } catch (e) {
          print("Still offline ❌");
        }
      }
    }
  }

  void openEditScreen() async {
    final updatedData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditScreen(checklist: checklist),
      ),
    );

    if (updatedData != null) {
      await updateChecklist(updatedData);
      await fetchChecklist();

      // ❌ REMOVED ImageUploadScreen (FIXED ERROR)
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            "EXTINGUISHER",
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: openEditScreen,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Text(
              "VIEW CHECKLIST",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                tableCell("ITEM", flex: 3, isHeader: true),
                tableCell("YES", isHeader: true),
                tableCell("NO", isHeader: true),
                tableCell("NA", isHeader: true),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: checklist.length,
                itemBuilder: (context, index) {
                  var item = checklist[index];

                  return Row(
                    children: [
                      tableCell(item["item"] ?? "", flex: 3),
                      tableCell(item["yes"] == true ? "✔" : ""),
                      tableCell(item["no"] == true ? "✔" : ""),
                      tableCell(item["na"] == true ? "✔" : ""),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// EDIT SCREEN
////////////////////////////////////////////////////////////

class EditScreen extends StatefulWidget {
  final List<Map<String, dynamic>> checklist;

  const EditScreen({super.key, required this.checklist});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late List<Map<String, dynamic>> checklist;

  @override
  void initState() {
    super.initState();
    checklist = List.from(widget.checklist);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Checklist")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: checklist.length,
              itemBuilder: (context, index) {
                var item = checklist[index];

                return Row(
                  children: [
                    tableCell(item["item"] ?? "", flex: 3),

                    tableCheckbox(
                      value: item["yes"] ?? false,
                      onChanged: (val) {
                        setState(() {
                          item["yes"] = val ?? false;
                          item["no"] = false;
                          item["na"] = false;
                        });
                      },
                    ),

                    tableCheckbox(
                      value: item["no"] ?? false,
                      onChanged: (val) {
                        setState(() {
                          item["no"] = val ?? false;
                          item["yes"] = false;
                          item["na"] = false;
                        });
                      },
                    ),

                    tableCheckbox(
                      value: item["na"] ?? false,
                      onChanged: (val) {
                        setState(() {
                          item["na"] = val ?? false;
                          item["yes"] = false;
                          item["no"] = false;
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context, checklist);
              },
              child: const Text(
                "SAVE",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// WIDGETS
////////////////////////////////////////////////////////////

Widget tableCell(String text, {int flex = 1, bool isHeader = false}) {
  return Expanded(
    flex: flex,
    child: Container(
      padding: const EdgeInsets.all(10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: isHeader ? Colors.grey.shade200 : Colors.white,
      ),
      child: Text(text),
    ),
  );
}

Widget tableCheckbox({
  required bool value,
  required Function(bool?) onChanged,
}) {
  return Expanded(
    child: Checkbox(value: value, onChanged: onChanged),
  );
}