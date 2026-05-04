import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'services/sprinkler_api_service.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final api = SprinklerApiService();
  final TextEditingController controller = TextEditingController();

  Map<String, dynamic>? item;
  bool showScanner = false;
  bool loading = false;

  void fetchData(String input) async {
    if (input.isEmpty) return;

    setState(() {
      loading = true;
      showScanner = false;
    });

    try {
      final result = await api.getEquipmentByQuery(input);

      setState(() {
        item = result == null ? null : _buildDisplayData(result);
        loading = false;
      });
    } catch (_) {
      setState(() {
        item = null;
        loading = false;
      });
    }
  }

  Map<String, dynamic> _buildDisplayData(Map<String, dynamic> raw) {
    final details = Map<String, dynamic>.from(raw["details"] ?? {});

    return {
      "SOS Code": raw["sos_code"] ?? "N/A",
      "Serial Number": raw["serial_number"] ?? "N/A",
      "Module": raw["module_name"] ?? "Sprinkler System",
      "Location": raw["location_name"] ?? "N/A",
      "Building": raw["building_name"] ?? "N/A",
      "Zone": raw["zone_name"] ?? "N/A",
      "Status": raw["status_bucket"] ?? raw["operational_status"] ?? "N/A",
      "Readiness Score": raw["readiness_score"]?.toString() ?? "N/A",
      "System Type": details["system_type"]?.toString() ?? "N/A",
      "Sprinkler Heads": details["sprinkler_count"]?.toString() ?? "N/A",
      "Coverage Area": details["coverage_area_sqm"]?.toString() ?? "N/A",
      "Operating Pressure":
          details["operating_pressure_bar"]?.toString() ?? "N/A",
      "Next Inspection Due": raw["next_inspection_due"] ?? "N/A",
      "Expiry Date": raw["expiry_date"] ?? "N/A",
    };
  }

  void onDetect(BarcodeCapture capture) {
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;

    controller.text = raw;

    setState(() {
      showScanner = false;
    });

    fetchData(raw);
  }

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
              ),
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
              Expanded(flex: 6, child: Text(e.value.toString())),
            ],
          ),
        );
      }).toList(),
    );
  }

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Scan & Get Details",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
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
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Enter SOS code or serial number",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        setState(() {
                          showScanner = !showScanner;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
          if (showScanner) scannerBox(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : item == null
                ? const Center(
                    child: Text(
                      "No sprinkler found. Scan or enter SOS code / serial number.",
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                : buildDetails(),
          ),
        ],
      ),
    );
  }
}
