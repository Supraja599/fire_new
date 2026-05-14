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
import 'services/apiservice.dart';

class HoseReelReportsPage extends StatefulWidget {
  const HoseReelReportsPage({super.key});

  @override
  State<HoseReelReportsPage> createState() => _HoseReelReportsPageState();
}

class _HoseReelReportsPageState extends State<HoseReelReportsPage> {
  final api = HoseReelApiService();
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  String selectedPlant = "Hose Reels";
  String selectedUnit = "UNIT-1";
  bool loading = false;
  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();

  @override
  void initState() { super.initState(); updateDateFields(); }
  void updateDateFields() { startController.text = DateFormat("dd/MM/yyyy").format(startDate); endController.text = DateFormat("dd/MM/yyyy").format(endDate); }

  Future pickDate(bool isStart) async {
    DateTime? picked = await showDatePicker(context: context, initialDate: isStart ? startDate : endDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null) { setState(() { if (isStart) startDate = picked; else endDate = picked; updateDateFields(); }); }
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchData() async {
    final equipment = await api.getEquipmentList();
    List<Map<String, dynamic>> byStatus(String status) => equipment.where((e) => e["status_bucket"]?.toString() == status).toList();
    return { "Active": byStatus("active"), "Needs Service": byStatus("needs-service"), "Due Inspection": byStatus("due-inspection"), "Expired": byStatus("expired") };
  }

  Future<void> generatePDF() async {
    setState(() => loading = true);
    try {
      if (!kIsWeb && Platform.isAndroid) { await Permission.manageExternalStorage.request(); }
      final dataMap = await fetchData();
      List<Map<String, dynamic>> allData = [];
      dataMap.forEach((status, list) => allData.addAll(list.map((e) => {...e, "status": status})));
      if (allData.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No data found"))); setState(() => loading = false); return; }

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
                pw.Text("ELTRIVE HOSE REEL REPORT", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                if (logoImage != null)
                  pw.Image(logoImage, width: 75, height: 75),
              ],
            ),
            pw.SizedBox(height: 10),
        pw.Text("Period: ${startController.text} to ${endController.text}"),
        pw.SizedBox(height: 20),
        pw.Table.fromTextArray(headers: ["SOS Code", "Location", "Status"], data: allData.map((e) => [ (e['sos_code'] ?? e['id'] ?? '').toString(), (e['location_name'] ?? '-').toString(), (e['status'] ?? '').toString() ]).toList()),
      ]));

      final dir = kIsWeb ? null : (Platform.isAndroid ? Directory('/storage/emulated/0/Download') : await getDownloadsDirectory());
      if (kIsWeb) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PDF generation not supported on web"))); return; }
      final saveDir = dir ?? await getApplicationDocumentsDirectory();
      final file = File("${saveDir.path}/HoseReel_Report_${DateTime.now().millisecondsSinceEpoch}.pdf");
      await file.writeAsBytes(await pdf.save());
      await OpenFilex.open(file.path);
    } catch (e) { debugPrint("PDF ERROR: $e"); }
    setState(() => loading = false);
  }

  Future<void> downloadExcel() async {
    setState(() => loading = true);
    try {
      if (!kIsWeb && Platform.isAndroid) { await Permission.manageExternalStorage.request(); }
      final dataMap = await fetchData();
      var excel = Excel.createExcel();
      dataMap.forEach((status, list) {
        Sheet sheet = excel[status];
        sheet.appendRow(["SOS Code", "Location", "Status"]);
        for (var item in list) { sheet.appendRow([ item['sos_code'] ?? item['id'] ?? '', item['location_name'] ?? '-', status ]); }
      });
      final dir = kIsWeb ? null : (Platform.isAndroid ? Directory('/storage/emulated/0/Download') : await getDownloadsDirectory());
      if (kIsWeb) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Excel generation not supported on web"))); return; }
      final saveDir = dir ?? await getApplicationDocumentsDirectory();
      final path = "${saveDir.path}/HoseReel_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      File file = File(path); await file.writeAsBytes(excel.encode()!); await OpenFilex.open(path);
    } catch (e) { debugPrint("EXCEL ERROR: $e"); }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hose Reel Reports"), backgroundColor: Colors.blue),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        Card(elevation: 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          DropdownButtonFormField<String>(value: selectedPlant, isExpanded: true, items: ["Hose Reels"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setState(() => selectedPlant = val!), decoration: const InputDecoration(labelText: "Plant", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: selectedUnit, isExpanded: true, items: ["UNIT-1", "UNIT-2", "UNIT-3"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setState(() => selectedUnit = val!), decoration: const InputDecoration(labelText: "Unit", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: TextField(controller: startController, readOnly: true, onTap: () => pickDate(true), decoration: const InputDecoration(labelText: "From Date", border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: endController, readOnly: true, onTap: () => pickDate(false), decoration: const InputDecoration(labelText: "To Date", border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)))),
          ]),
        ]))),
        const SizedBox(height: 30),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.picture_as_pdf), label: const Text("Generate PDF"), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: loading ? null : generatePDF)),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.table_chart), label: const Text("Download Excel"), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: loading ? null : downloadExcel)),
      ])),
    );
  }
}
