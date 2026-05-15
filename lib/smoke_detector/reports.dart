import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:fire_new/utils/web_download_helper.dart';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'services/smoke_detector_api_service.dart';

class SmokeDetectorReportsPage extends StatefulWidget {
  const SmokeDetectorReportsPage({super.key});
  @override
  State<SmokeDetectorReportsPage> createState() => _SmokeDetectorReportsPageState();
}

class _SmokeDetectorReportsPageState extends State<SmokeDetectorReportsPage> {
  final api = SmokeDetectorApiService();
  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();
  String selectedPlant = "Smoke Detectors";
  String selectedUnit = "UNIT-1";
  bool loading = false;

  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateDateFields();
  }

  void _updateDateFields() {
    startController.text = DateFormat("dd/MM/yyyy").format(startDate);
    endController.text = DateFormat("dd/MM/yyyy").format(endDate);
  }

  Future<void> _pickDate(bool isStart) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) startDate = picked; else endDate = picked;
        _updateDateFields();
      });
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchData() async {
    await api.syncModuleData();
    final equipment = await api.getEquipmentList();
    List<Map<String, dynamic>> byStatus(String status) {
      return equipment.where((e) => (e["status_bucket"]?.toString() ?? e["status"]?.toString() ?? "").toLowerCase().contains(status.toLowerCase())).toList();
    }
    return {
      "Active": byStatus("active"),
      "Needs Service": byStatus("needs-service"),
      "Due Inspection": byStatus("due-inspection"),
      "Expired": byStatus("expired"),
    };
  }

  Future<void> generatePDF() async {
    setState(() => loading = true);
    try {
      final dataMap = await _fetchData();
      final allData = <Map<String, dynamic>>[];
      dataMap.forEach((k, v) => allData.addAll(v.map((e) => {...e, "status_label": k})));

      if (allData.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No equipment data found")));
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
      pdf.addPage(pw.MultiPage(maxPages: 1000, 
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
                pw.Text("ELTRIVE SMOKE DETECTOR SAFETY REPORT", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                if (logoImage != null)
                  pw.Image(logoImage, width: 75, height: 75),
              ],
            ),
            pw.SizedBox(height: 10),
          pw.Text("Plant: $selectedPlant | Unit: $selectedUnit"),
          pw.Text("Period: ${startController.text} to ${endController.text}"),
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
      ));

      if (kIsWeb) {
        WebDownloadHelper.downloadFile(await pdf.save(), "Report_${DateTime.now().millisecondsSinceEpoch}.pdf");
        if (mounted) { setState(() => loading = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PDF Downloaded ✅"))); }
        return;
      }
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/SmokeDetector_Report_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PDF Generated. Opening...")));
        await OpenFilex.open(path);
      }
    } catch (e) {
      if (mounted) { setState(() => loading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"))); }
    }
  }

  Future<void> generateExcel() async {
    setState(() => loading = true);
    try {
      final dataMap = await _fetchData();
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

      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/SmokeDetector_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final file = File(path);
      await file.writeAsBytes(excel.encode()!);
      
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Excel Generated. Opening...")));
        await OpenFilex.open(path);
      }
    } catch (e) {
      if (mounted) { setState(() => loading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"))); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Reports"), backgroundColor: Colors.blue, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                DropdownButtonFormField<String>(
                  value: selectedPlant,
                  isExpanded: true,
                  items: ["Smoke Detectors"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => selectedPlant = val!),
                  decoration: const InputDecoration(labelText: "Plant", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedUnit,
                  isExpanded: true,
                  items: ["UNIT-1", "UNIT-2", "UNIT-3"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => selectedUnit = val!),
                  decoration: const InputDecoration(labelText: "Unit", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                Row(children: [
                  Expanded(child: TextField(controller: startController, readOnly: true, onTap: () => _pickDate(true), decoration: const InputDecoration(labelText: "From Date", border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: endController, readOnly: true, onTap: () => _pickDate(false), decoration: const InputDecoration(labelText: "To Date", border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)))),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 40),
          _actionBtn("Generate PDF Report", Icons.picture_as_pdf, Colors.red, generatePDF),
          const SizedBox(height: 15),
          _actionBtn("Download Excel Sheet", Icons.table_chart, Colors.green, generateExcel),
        ]),
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        onPressed: loading ? null : onTap,
      ),
    );
  }
}