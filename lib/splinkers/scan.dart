import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final TextEditingController controller = TextEditingController();

  Map<String, dynamic>? item;
  bool showScanner = false;
  bool loading = false;

  /// 🔥 DUMMY DATA
  Map<String, dynamic> getDummyData(String id) {
    return {
      "ID": id,
      "Location": "Zone 3",
      "Pressure": "85 PSI",
      "Status": "Active",
      "Last Checked": "12/04/2026",
      "Technician": "Ravi Kumar",
    };
  }

  /// 🔍 FETCH DATA
  void fetchData(String input) async {
    if (input.isEmpty) return;

    setState(() {
      loading = true;
      showScanner = false;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      item = getDummyData(input);
      loading = false;
    });
  }

  /// 📷 SCAN
  void onDetect(BarcodeCapture capture) {
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;

    controller.text = raw;

    setState(() {
      showScanner = false;
    });

    fetchData(raw);
  }

  /// 📋 DETAILS UI
  Widget buildDetails() {
    final entries = item!.entries.toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: entries.map((e) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
              )
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  e.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 6,
                child: Text(e.value.toString()),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 📷 SCANNER BOX
  Widget scannerBox() {
    return Container(
      margin: const EdgeInsets.all(12),
      height: 230,
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
      backgroundColor: const Color(0xFFF4F6FA),

      /// 🔴 APP BAR WITH RED TITLE
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Scan & Get Details",
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [

          /// 🔍 INPUT BOX
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                )
              ],
            ),
            child: Column(
              children: [

                /// TEXT FIELD
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Enter ID manually",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner,
                          color: Colors.red),
                      onPressed: () {
                        setState(() {
                          showScanner = !showScanner;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                /// BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      fetchData(controller.text);
                    },
                    child: const Text("Get Details"),
                  ),
                ),
              ],
            ),
          ),

          /// 📷 SCANNER
          if (showScanner) scannerBox(),

          /// 📋 RESULTS
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : item == null
                ? const Center(
              child: Text(
                "Scan or enter ID to view details",
                style: TextStyle(color: Colors.grey),
              ),
            )
                : buildDetails(),
          ),
        ],
      ),
    );
  }
}