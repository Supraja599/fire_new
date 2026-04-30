import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanScreen extends StatefulWidget {
  final VoidCallback onBackToHome;

  const ScanScreen({super.key, required this.onBackToHome});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  String result = "";
  bool openScanner = false;

  final TextEditingController manualController = TextEditingController();
  final MobileScannerController controller = MobileScannerController();

  /// 🔍 SCAN
  void onDetect(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;

    final value = capture.barcodes.first.rawValue;

    if (value != null) {
      setState(() {
        result = value;
        openScanner = false;
      });

      controller.stop();
    }
  }

  void startScan() {
    setState(() => openScanner = true);
    controller.start();
  }

  void closeScanner() {
    setState(() => openScanner = false);
    controller.stop();
  }

  @override
  void dispose() {
    manualController.dispose();
    controller.dispose();
    super.dispose();
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.onBackToHome();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,

        /// 🔴 APP BAR (SIMPLE)
        appBar: AppBar(
          backgroundColor: Colors.red,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: widget.onBackToHome,
          ),
          title: const Text(
            "Scan Asset",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),

        body: Stack(
          children: [

            /// MAIN CONTENT
            ListView(
              padding: const EdgeInsets.all(16),
              children: [

                /// 🔴 SCAN BUTTON CARD
                GestureDetector(
                  onTap: startScan,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.qr_code_scanner,
                            size: 50, color: Colors.white),
                        SizedBox(height: 10),
                        Text(
                          "Tap to Scan",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// ✏️ MANUAL ENTRY
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [

                      TextField(
                        controller: manualController,
                        decoration: const InputDecoration(
                          hintText: "Enter Asset ID",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              result = manualController.text;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text("Submit"),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// 📋 RESULT
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    result.isEmpty
                        ? "No data"
                        : "Scanned: $result",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),

            /// 📷 SCANNER
            if (openScanner)
              Container(
                color: Colors.white,
                child: Column(
                  children: [

                    const SizedBox(height: 40),

                    const Text("Scan Code"),

                    Expanded(
                      child: MobileScanner(
                        controller: controller,
                        onDetect: onDetect,
                      ),
                    ),

                    ElevatedButton(
                      onPressed: closeScanner,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text("Close"),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}