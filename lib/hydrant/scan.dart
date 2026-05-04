import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'services/hydrant_api_service.dart';

class HydrantScanPage extends StatefulWidget {
  const HydrantScanPage({super.key});

  @override
  State<HydrantScanPage> createState() => _HydrantScanPageState();
}

class _HydrantScanPageState extends State<HydrantScanPage> {
  final api = HydrantApiService();
  final TextEditingController controller = TextEditingController();
  Map<String, dynamic>? record;
  bool showScanner = false;
  bool loading = false;

  Future<void> _search(String value) async {
    final query = value.trim();
    if (query.isEmpty) return;
    setState(() => loading = true);
    final found = await api.getEquipmentByQuery(query);
    if (!mounted) return;
    setState(() {
      record = found;
      loading = false;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;
    controller.text = raw;
    setState(() => showScanner = false);
    _search(raw);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final details = Map<String, dynamic>.from(record?["details"] ?? {});

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Hydrant Scan"),
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
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Enter SOS ID",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => showScanner = !showScanner),
                      icon: const Icon(Icons.qr_code_scanner),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _search(controller.text),
                    child: const Text("Search"),
                  ),
                ),
              ],
            ),
          ),
          if (showScanner)
            Container(
              height: 220,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
              ),
              child: MobileScanner(onDetect: _onDetect),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : record == null
                    ? const Center(child: Text("Scan or enter a hydrant SOS ID"))
                    : ListView(
                        padding: const EdgeInsets.all(14),
                        children: [
                          _row("SOS ID", (record!["sos_code"] ?? "-").toString()),
                          _row("Location", (record!["location_name"] ?? "-").toString()),
                          _row("Building", (record!["building_name"] ?? "-").toString()),
                          _row("Zone", (record!["zone_name"] ?? "-").toString()),
                          _row("Status", (record!["status_bucket"] ?? "-").toString()),
                          _row("Pressure", (details["operating_pressure_bar"] ?? "-").toString()),
                          _row("Flow Rate", (details["flow_rate_lpm"] ?? "-").toString()),
                          _row("Hose Length", (details["hose_length_m"] ?? "-").toString()),
                          _row("Next Inspection", (record!["next_inspection_due"] ?? "-").toString()),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _row(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(flex: 6, child: Text(value)),
        ],
      ),
    );
  }
}
