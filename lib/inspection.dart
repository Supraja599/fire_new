import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hive/hive.dart';
import 'checklist.dart';
import 'services/apiservice.dart';

class InspectionPage extends StatefulWidget {
  const InspectionPage({super.key});

  @override
  State<InspectionPage> createState() => _InspectionPageState();
}

class _InspectionPageState extends State<InspectionPage> {
  final TextEditingController idController = TextEditingController();

  String? scannedId;
  Map<String, dynamic>? item;
  bool loading = false;
  String? error;
  bool showScanner = false;
  bool showSearch = true;

  final box = Hive.box('inspectionBox');
  List<String> suggestions = [];

  String _clean(String value) {
    return value
        .trim()
        .replaceAll("\n", "")
        .replaceAll(" ", "")
        .replaceAll("-", "")
        .toUpperCase();
  }

  void openChecklistPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChecklistPage()),
    );
  }

  // ✅ ONLY STORE SCANNED ID
  void onDetect(BarcodeCapture capture) {
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;

    final cleaned = _clean(raw);

    setState(() {
      showScanner = false;
      idController.text = cleaned;
      scannedId = cleaned;
    });
  }

  Future<void> fetchDetails(String input) async {
    setState(() {
      loading = true;
      error = null;
      showSearch = false;
    });

    try {
      final id = _clean(input);
      final data = await ApiService.searchAny(id);

      if (data == null || data.isEmpty) {
        setState(() {
          loading = false;
          error = "No data found for $id";
          showSearch = true;
        });
        return;
      }

      setState(() {
        item = data;
        scannedId = id;
        loading = false;
      });

      box.put(id, data);
    } catch (e) {
      setState(() {
        loading = false;
        error = "Connection Error: $e";
        showSearch = true;
      });
    }
  }

  void updateSuggestions(String input) {
    final keys = box.keys.whereType<String>().toList();

    setState(() {
      suggestions = keys
          .where((e) => e.contains(_clean(input)))
          .take(5)
          .toList();
    });
  }

  Future<void> saveData() async {
    if (item == null || scannedId == null) return;

    setState(() => loading = true);

    final success = await ApiService.insertVersion(item!);

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? "Saved Successfully ✅" : "Save Failed ❌"),
      ),
    );
  }

  void editField(String key, String value) {
    final controller = TextEditingController(text: value);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Edit $key"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                item![key] = controller.text;
              });

              box.put(scannedId, item);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED TABLE (FULL SCREEN + SCROLL)
  Widget buildTable() {
    if (item == null) {
      return const Center(
        child: Text("Scan or Enter ID to view details"),
      );
    }

    final entries = item!.entries.toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          color: Colors.red.withOpacity(0.1),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text("FIELD")),
              Expanded(flex: 4, child: Text("VALUE")),
              Expanded(flex: 2, child: Text("EDIT")),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ✅ FULL SCREEN SCROLLABLE LIST
        Expanded(
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final e = entries[i];

              return Container(
                margin: const EdgeInsets.symmetric(
                    vertical: 4, horizontal: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(e.key.toString())),
                    Expanded(flex: 4, child: Text(e.value.toString())),
                    Expanded(
                      flex: 2,
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => editField(
                          e.key.toString(),
                          e.value.toString(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildScannerBox() {
    return Container(
      margin: const EdgeInsets.all(12),
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: MobileScanner(onDetect: onDetect),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text("Inspection System"),
        backgroundColor: Colors.red,
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: saveData),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                item = null;
                scannedId = null;
                idController.clear();
                error = null;
                showSearch = true;
              });
            },
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (showSearch)
                      Container(
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: idController,
                              onChanged: updateSuggestions,
                              decoration: InputDecoration(
                                hintText: "Enter Barcode or SOS Code",
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.qr_code_scanner,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(
                                            () => showScanner = !showScanner);
                                  },
                                ),
                              ),
                            ),

                            if (suggestions.isNotEmpty)
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  itemCount: suggestions.length,
                                  itemBuilder: (_, i) => ListTile(
                                    title: Text(suggestions[i]),
                                    onTap: () {
                                      idController.text = suggestions[i];
                                      fetchDetails(suggestions[i]);
                                      setState(() => suggestions.clear());
                                    },
                                  ),
                                ),
                              ),

                            const SizedBox(height: 10),

                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              onPressed: () {
                                final input = _clean(idController.text);
                                if (input.isEmpty) return;
                                fetchDetails(input);
                              },
                              child: const Text("Search"),
                            ),
                          ],
                        ),
                      ),

                    if (showScanner) buildScannerBox(),

                    // ✅ FULL SCREEN FIX (NO HALF PAGE ISSUE)
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.65,
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : error != null
                          ? Center(
                        child: Text(error!,
                            style: const TextStyle(
                                color: Colors.red)),
                      )
                          : buildTable(),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.list),
                label: const Text(
                  "Open Checklist",
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: openChecklistPage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}