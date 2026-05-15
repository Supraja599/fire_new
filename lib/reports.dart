
import 'package:flutter/material.dart';
import 'package:fire_new/utils/web_download_helper.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'services/apiservice.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  String selectedPlant = "Fire Extinguishers";
  String selectedUnit = "UNIT-1";

  bool loading = false;

  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();

  @override
  void initState() {
    super.initState();
    updateDateFields();
  }

  void updateDateFields() {
    startController.text = DateFormat("dd/MM/yyyy").format(startDate);
    endController.text = DateFormat("dd/MM/yyyy").format(endDate);
  }

  // ================= DATE PICKER =================
  Future pickDate(bool isStart) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      if (isStart && picked.isAfter(endDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Start date cannot be after End date")),
        );
        return;
      }

      if (!isStart && picked.isBefore(startDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("End date cannot be before Start date")),
        );
        return;
      }

      setState(() {
        isStart ? startDate = picked : endDate = picked;
        updateDateFields();
      });
    }
  }

  // ================= FETCH =================
  Future<Map<String, List<Map<String, dynamic>>>> fetchData() async {
    final active = await ApiService.getActive();
    final service = await ApiService.getNeedsService();
    final due = await ApiService.getDueInspection();
    final expired = await ApiService.getExpired();

    return {
      "Active": active,
      "Needs Service": service,
      "Due Inspection": due,
      "Expired": expired,
    };
  }

  // ================= PDF =================
  Future<void> generatePDF() async {
    setState(() => loading = true);

    try {
      final dataMap = await fetchData();

      List<Map<String, dynamic>> allData = [];

      dataMap.forEach((status, list) {
        allData.addAll(list.map((e) => {...e, "status": status}));
      });

      if (allData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No data to generate PDF")),
        );
        setState(() => loading = false);
        return;
      }

      final pdf = pw.Document();
      pw.MemoryImage? logoImage;
      try {
        final logoBytes = await rootBundle.load('assets/eltrive_logo.jpg');
        logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      } catch (e) {
        print("Logo load error: $e");
      }

      pdf.addPage(
        pw.MultiPage(maxPages: 1000, 
          pageTheme: pw.PageTheme(
            buildBackground: (context) {
              return pw.FullPage(
                ignoreMargins: true,
                child: pw.Center(
                  child: pw.Transform.rotate(
                    angle: 0.6, // Professional upward-diagonal tilt
                    child: pw.Opacity(
                      opacity: 0.12, // Perfect balance of high visibility & readability
                      child: pw.Text(
                        "ELTRIVE",
                        style: pw.TextStyle(
                          fontSize: 130,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          build: (context) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("ELTRIVE PLANT REPORT",
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
                if (logoImage != null)
                  pw.Image(logoImage, width: 75, height: 75),
              ],
            ),

            pw.SizedBox(height: 10),

            pw.Text("Plant: $selectedPlant"),
            pw.Text("Unit: $selectedUnit"),
            pw.Text(
                "Date: ${DateFormat("dd-MM-yyyy").format(startDate)} to ${DateFormat("dd-MM-yyyy").format(endDate)}"),

            pw.SizedBox(height: 20),

            pw.Text("Summary",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

            pw.SizedBox(height: 5),
            pw.Column(
              children: dataMap.entries.map((e) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    children: [
                      pw.SizedBox(
                        width: 180,
                        child: pw.Text("${e.key}:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Text("${e.value.length}"),
                    ],
                  ),
                );
              }).toList(),
            ),

            pw.SizedBox(height: 20),

            pw.Table.fromTextArray(
          headers: ["SOS Code", "Location", "Status", "Previous Inspection", "Next Inspection"],
          data: allData.map((e) {
            final statusVal = (e['status_label'] ?? e['status'] ?? '-').toString();
            final prevIns = (e['last_inspection_date'] ?? e['last_service_date'] ?? e['last_service'] ?? e['last_inspected'] ?? e['last_inspected_at'] ?? e['inspected_date'] ?? e['inspection_date'] ?? e['updated_at'] ?? e['previous_inspection'] ?? '-').toString();
            final nextIns = (e['next_inspection_due'] ?? e['next_due_date'] ?? '-').toString();
            return [
              (e['sos_code'] ?? e['id'] ?? '-').toString(),
              (e['location_name'] ?? e['building_name'] ?? '-').toString(),
              statusVal,
              prevIns,
              nextIns,
            ];
          }).toList(),
        ),
          ],
        ),
      );

      final fileName = "Report_${DateTime.now().millisecondsSinceEpoch}.pdf";
      
      if (kIsWeb) {
        WebDownloadHelper.downloadFile(await pdf.save(), fileName);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PDF downloaded ✅")));
        setState(() => loading = false);
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/$fileName";
      final file = File(path);

      await file.writeAsBytes(await pdf.save());
      await OpenFilex.open(path);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PDF generated and opened ✅")),
      );
    } catch (e) {
      print("PDF ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generating PDF: $e")),
      );
    }

    setState(() => loading = false);
  }

  // ================= EXCEL =================
  Future<void> downloadExcel() async {
    setState(() => loading = true);

    try {
      final dataMap = await fetchData();

      var excel = Excel.createExcel();

      dataMap.forEach((status, list) {
        Sheet sheet = excel[status];
        sheet.appendRow(["SOS CODE", "LOCATION", "STATUS", "LAST INSPECTION", "NEXT INSPECTION"]);
        for (var item in list) {
          final prevIns = (item['last_inspection_date'] ?? item['last_service_date'] ?? item['last_service'] ?? item['last_inspected'] ?? item['last_inspected_at'] ?? item['inspected_date'] ?? item['inspection_date'] ?? item['updated_at'] ?? item['previous_inspection'] ?? '-').toString();
          final nextIns = (item['next_inspection_due'] ?? item['next_due_date'] ?? '-').toString();
          sheet.appendRow([
            (item['sos_code'] ?? item['id'] ?? '-').toString(),
            (item['location_name'] ?? item['building_name'] ?? '-').toString(),
            status,
            prevIns,
            nextIns,
          ]);
        }
      });

      final fileName = "Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";

      if (kIsWeb) {
        WebDownloadHelper.downloadFile(excel.encode()!, fileName);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Excel downloaded ✅")));
        setState(() => loading = false);
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/$fileName";
      File file = File(path);

      await file.writeAsBytes(excel.encode()!);
      await OpenFilex.open(path);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Excel generated and opened ✅")),
      );
    } catch (e) {
      print("EXCEL ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generating Excel: $e")),
      );
    }

    setState(() => loading = false);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [

                    // ✅ FIXED DROPDOWN UI (NO OVERFLOW)
                    DropdownButtonFormField<String>(
                      value: selectedPlant,
                      isExpanded: true,
                      items: [
                        "Fire Extinguishers",
                        "Hose Reel",
                        "Drum Hose Reel"
                      ]
                          .map((e) => DropdownMenuItem(
                          value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedPlant = val!),
                      decoration: const InputDecoration(
                        labelText: "Plant",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: selectedUnit,
                      isExpanded: true,
                      items: ["UNIT-1", "UNIT-2", "UNIT-3"]
                          .map((e) => DropdownMenuItem(
                          value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedUnit = val!),
                      decoration: const InputDecoration(
                        labelText: "Unit",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startController,
                            readOnly: true,
                            onTap: () => pickDate(true),
                            decoration: const InputDecoration(
                              labelText: "From Date",
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: endController,
                            readOnly: true,
                            onTap: () => pickDate(false),
                            decoration: const InputDecoration(
                              labelText: "To Date",
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ✅ MODERN BUTTONS
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Generate PDF"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: loading ? null : generatePDF,
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.table_chart),
                label: const Text("Download Excel"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: loading ? null : downloadExcel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

