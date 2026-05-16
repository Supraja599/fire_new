import 'dart:io';
import 'package:pdf/pdf.dart';

import 'package:fire_new/utils/web_download_helper.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'services/sprinkler_api_service.dart';

class SprinklerReportsPage extends StatefulWidget {
  const SprinklerReportsPage({super.key});

  @override
  State<SprinklerReportsPage> createState() => _SprinklerReportsPageState();
}

class _SprinklerReportsPageState extends State<SprinklerReportsPage> {
  final api = SprinklerApiService();
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  String selectedPlant = "Fire Sprinkler";
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
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) startDate = picked; else endDate = picked;
      _updateDateFields();
    });
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchData() async {
    final equipment = await api.getEquipmentList();
    List<Map<String, dynamic>> byStatus(String status) {
      return equipment.where((item) => item["status_bucket"]?.toString() == status).toList();
    }
    return { "Active": byStatus("active"), "Needs Service": byStatus("needs-service"), "Due Inspection": byStatus("due-inspection"), "Expired": byStatus("expired") };
  }

  Future<void> _generatePdf() async {
    setState(() => loading = true);
    try {
      
      final dataMap = await _fetchData();
      final allData = <Map<String, dynamic>>[];
      dataMap.forEach((status, list) => allData.addAll(list.map((item) => {...item, "status": status})));

      if (allData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No data found")));
        setState(() => loading = false); return;
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
                pw.Text("ELTRIVE SPRINKLER REPORTS", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                if (logoImage != null)
                  pw.Image(logoImage, width: 75, height: 75),
              ],
            ),
            pw.SizedBox(height: 10),
        pw.Text("Period: ${startController.text} to ${endController.text}"),
        pw.SizedBox(height: 20),
        pw.Table.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
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
      ]));

      
      final fileName = "Sprinkler_Report_${DateTime.now().millisecondsSinceEpoch}.pdf";

      if (kIsWeb) {
        WebDownloadHelper.downloadFile(await pdf.save(), "Report_${DateTime.now().millisecondsSinceEpoch}.pdf");
        if (mounted) { setState(() => loading = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PDF Downloaded ✅"))); }
        return;
      }

      final saveDir = await getApplicationDocumentsDirectory();
      final file = File("${saveDir.path}/$fileName");
      await file.writeAsBytes(await pdf.save());
      await OpenFilex.open(file.path);
    } catch (e) { debugPrint("PDF ERROR: $e"); }
    setState(() => loading = false);
  }

  Future<void> _downloadExcel() async {
    setState(() => loading = true);
    try {
      
      final dataMap = await _fetchData();
      final excel = Excel.createExcel();
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

      
      final fileName = "Sprinkler_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";

      if (kIsWeb) {
        WebDownloadHelper.downloadFile(excel.encode()!, "Report_${DateTime.now().millisecondsSinceEpoch}.xlsx");
        if (mounted) { setState(() => loading = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Excel Downloaded ✅"))); }
        return;
      }

      final saveDir = await getApplicationDocumentsDirectory();
      final file = File("${saveDir.path}/$fileName");
      await file.writeAsBytes(excel.encode()!);
      await OpenFilex.open(file.path);
    } catch (e) { debugPrint("EXCEL ERROR: $e"); }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reports"), backgroundColor: Colors.blue),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        Card(elevation: 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          DropdownButtonFormField<String>(value: selectedPlant, isExpanded: true, items: const ["Fire Sprinkler"].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: (v) => setState(() => selectedPlant = v!), decoration: const InputDecoration(labelText: "Plant", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: selectedUnit, isExpanded: true, items: const ["UNIT-1", "UNIT-2", "UNIT-3"].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: (v) => setState(() => selectedUnit = v!), decoration: const InputDecoration(labelText: "Unit", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: TextField(controller: startController, readOnly: true, onTap: () => _pickDate(true), decoration: const InputDecoration(labelText: "From", border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: endController, readOnly: true, onTap: () => _pickDate(false), decoration: const InputDecoration(labelText: "To", border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)))),
          ]),
        ]))),
        const SizedBox(height: 30),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.picture_as_pdf), label: const Text("Generate PDF"), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: loading ? null : _generatePdf)),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.table_chart), label: const Text("Download Excel"), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: loading ? null : _downloadExcel)),
      ])),
    );
  }
}