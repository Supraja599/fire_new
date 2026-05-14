import 'dart:io';
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
      if (!kIsWeb && Platform.isAndroid) {
        await Permission.manageExternalStorage.request();
      }
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
      pdf.addPage(pw.MultiPage(
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
          headers: ["SOS Code", "Location", "Status"],
          data: allData.map((item) => [ (item["sos_code"] ?? item["id"] ?? "").toString(), (item["location_name"] ?? "-").toString(), (item["status"] ?? "").toString() ]).toList(),
        ),
      ]));

      final dir = kIsWeb ? null : (Platform.isAndroid ? Directory('/storage/emulated/0/Download') : await getDownloadsDirectory());
      final fileName = "Sprinkler_Report_${DateTime.now().millisecondsSinceEpoch}.pdf";

      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PDF generation not fully supported on web yet")));
        return;
      }

      final saveDir = dir ?? await getApplicationDocumentsDirectory();
      final file = File("${saveDir.path}/$fileName");
      await file.writeAsBytes(await pdf.save());
      await OpenFilex.open(file.path);
    } catch (e) { debugPrint("PDF ERROR: $e"); }
    setState(() => loading = false);
  }

  Future<void> _downloadExcel() async {
    setState(() => loading = true);
    try {
      if (!kIsWeb && Platform.isAndroid) {
        await Permission.manageExternalStorage.request();
      }
      final dataMap = await _fetchData();
      final excel = Excel.createExcel();
      dataMap.forEach((status, list) {
        final sheet = excel[status];
        sheet.appendRow(["SOS Code", "Location", "Status"]);
        for (final item in list) { sheet.appendRow([ item["sos_code"] ?? item["id"] ?? "", item["location_name"] ?? "-", status ]); }
      });

      final dir = kIsWeb ? null : (Platform.isAndroid ? Directory('/storage/emulated/0/Download') : await getDownloadsDirectory());
      final fileName = "Sprinkler_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";

      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Excel generation not fully supported on web yet")));
        return;
      }

      final saveDir = dir ?? await getApplicationDocumentsDirectory();
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
