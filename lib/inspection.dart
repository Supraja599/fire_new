import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Future<void> openNavigation() async {
    const double lat = 17.5064803;
    const double lng = 78.3554442;

    final Uri uri = Uri.parse("geo:$lat,$lng?q=$lat,$lng");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final Uri webUrl = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
      );
      await launchUrl(webUrl);
    }
  }

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
    final id = _clean(input);

    setState(() {
      loading = true;
      error = null;
      showSearch = false;
    });

    try {
      final localData = box.get(id);

      if (localData != null) {
        setState(() {
          item = Map<String, dynamic>.from(localData);
          scannedId = id;
          loading = false;
        });
        return;
      }

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
        content: Text(success ? "Saved Successfully ✅" : "Saved"),
      ),
    );
  }

  void editAllFields() {
    if (item == null) return;

    final controllers = <String, TextEditingController>{};

    item!.forEach((key, value) {
      controllers[key] = TextEditingController(text: value.toString());
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Details"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              children: controllers.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: TextField(
                    controller: e.value,
                    decoration: InputDecoration(
                      labelText: e.key,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              controllers.forEach((key, controller) {
                item![key] = controller.text;
              });

              box.put(scannedId, item);
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget buildTable() {
    final entries = item!.entries.toList();

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  "FIELD",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 6,
                child: Text(
                  "VALUE",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        ...entries.map((e) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    e.key.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Text(e.value.toString()),
                ),
              ],
            ),
          );
        }),
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
          IconButton(icon: const Icon(Icons.edit), onPressed: editAllFields),
          IconButton(icon: const Icon(Icons.navigation), onPressed: openNavigation),
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
            if (showSearch)
              Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(10),
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
                            setState(() => showScanner = !showScanner);
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

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                  ? Center(
                child: Text(
                  error!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
                  : item == null
                  ? const Center(
                child: Text("Scan or Enter ID to view details"),
              )
                  : buildTable(),
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
                label: const Text("Open Checklist",
                    style: TextStyle(fontSize: 18)),
                onPressed: openChecklistPage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}