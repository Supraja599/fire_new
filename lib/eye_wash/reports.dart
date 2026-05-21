import 'dart:io';
import 'package:pdf/pdf.dart';

import 'package:flutter/foundation.dart';

import 'package:fire_new/utils/web_download_helper.dart';
import 'package:fire_new/common/report_utils.dart';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:fire_new/local_db.dart';
import 'package:fire_new/services/apiservice.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'services/api_service.dart';

class EyeWashReportsPage extends StatefulWidget {
  const EyeWashReportsPage({super.key});
  @override
  State<EyeWashReportsPage> createState() => _EyeWashReportsPageState();
}

class _EyeWashReportsPageState extends State<EyeWashReportsPage> {
  final api = EyeWashApiService();
  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();
  String selectedPlant = "EyeWash";
  String selectedUnit = "UNIT-1";
  bool loading = false;
  final TextEditingController sosController = TextEditingController();
  final TextEditingController inspectorNameController = TextEditingController();

  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();

  @override
  void initState() { super.initState(); _updateDateFields(); _prefillLatestInspection(); }

  void _updateDateFields() {
    startController.text = DateFormat("dd/MM/yyyy").format(startDate);
    endController.text = DateFormat("dd/MM/yyyy").format(endDate);
  }

  Future<void> _pickDate(bool isStart) async {
    DateTime? picked = await showDatePicker(context: context, initialDate: isStart ? startDate : endDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null) { setState(() { if (isStart) startDate = picked; else endDate = picked; _updateDateFields(); }); }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchReportData() async {
    await api.syncModuleData();
    final equipment = await api.getEquipmentList();
    List<Map<String, dynamic>> byStatus(String status) {
      return equipment.where((e) => matchesReportStatus(e, status)).toList();
    }
    return { "Active": byStatus("active"), "Needs Service": byStatus("needs-service"), "Due Inspection": byStatus("due-inspection"), "Expired": byStatus("expired") };
  }

  Future<void> generatePDF() async {
    setState(() => loading = true);
    try {
      final dataMap = await _fetchReportData();
      final allData = <Map<String, dynamic>>[];
      dataMap.forEach((k, v) => allData.addAll(v.map((e) => {...e, "status_label": k})));

      if (allData.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No data found")));
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
                pw.Text("ELTRIVE EYE WASH SAFETY REPORT", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                if (logoImage != null)
                  pw.Image(logoImage, width: 75, height: 75),
              ],
            ),
            pw.SizedBox(height: 10),
        pw.Text("Plant: $selectedPlant | Unit: $selectedUnit"),
        pw.Text("Period: ${startController.text} to ${endController.text}"),
        pw.SizedBox(height: 20),
        pw.Table.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          headers: ["SOS Code", "Location", "Status", "Previous Inspection", "Next Inspection"],
          data: allData.map((e) {
            final statusVal = reportStatus(e);
            final prevIns = reportPreviousInspection(e);
            final nextIns = reportNextInspection(e);
            return [
              reportEquipmentId(e),
              reportLocation(e),
              statusVal,
              prevIns,
              nextIns,
            ];
          }).toList(),
        ),
      ]));

      if (kIsWeb) {
        WebDownloadHelper.downloadFile(await pdf.save(), "Report_${DateTime.now().millisecondsSinceEpoch}.pdf");
        if (mounted) { setState(() => loading = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PDF Downloaded ✅"))); }
        return;
      }
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/eye_wash_Report_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File(path); await file.writeAsBytes(await pdf.save());
      if (mounted) { setState(() => loading = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PDF Generated. Opening..."))); await OpenFilex.open(path); }
    } catch (e) { if (mounted) { setState(() => loading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"))); } }
  }

  Future<void> generateExcel() async {
    setState(() => loading = true);
    try {
      final dataMap = await _fetchReportData();
      var excel = Excel.createExcel();
      dataMap.forEach((status, list) {
        Sheet sheet = excel[status];
        sheet.appendRow(["SOS CODE", "LOCATION", "STATUS", "LAST INSPECTION", "NEXT INSPECTION"]);
        for (var item in list) {
          final prevIns = reportPreviousInspection(item);
          final nextIns = reportNextInspection(item);
          sheet.appendRow([
            reportEquipmentId(item),
            reportLocation(item),
            status,
            prevIns,
            nextIns,
          ]);
        }
      });
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/eye_wash_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final file = File(path); await file.writeAsBytes(excel.encode()!);
      if (mounted) { setState(() => loading = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Excel Generated. Opening..."))); await OpenFilex.open(path); }
    } catch (e) { if (mounted) { setState(() => loading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"))); } }
  }


  Future<void> _prefillLatestInspection() async {
    try {
      final pendingList = await LocalDB.getAllModuleInspections(moduleCode: EyeWashApiService.moduleCode);
      if (pendingList.isNotEmpty) {
        final last = pendingList.last;
        final payload = last['payload'] as Map<String, dynamic>?;
        if (mounted) {
          setState(() {
            sosController.text = last['equipment_id']?.toString() ?? '';
            inspectorNameController.text = payload?['inspector_name']?.toString() ?? '';
          });
        }
      }
    } catch (e) {
      print("Prefill error: $e");
    }
  }

  Future<void> generateSinglePDF() async {
    final sosCode = sosController.text.trim();
    if (sosCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter SOS Number")));
      return;
    }
    setState(() => loading = true);
    try {
      final eqData = await api.getEquipmentByQuery(sosCode);
      if (eqData == null || eqData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Equipment $sosCode not found")));
        setState(() => loading = false);
        return;
      }
      final pendingList = await LocalDB.getAllModuleInspections(moduleCode: EyeWashApiService.moduleCode);
      final latestInspection = pendingList.where((e) => e['equipment_id'].toString().toLowerCase() == sosCode.toLowerCase()).toList();
      Map<String, dynamic> payload = {};
      if (latestInspection.isNotEmpty) {
        payload = latestInspection.last['payload'] as Map<String, dynamic>;
      } else {
        // Fallback: fetch from backend (handles reinstall / data cleared after 1 year)
        try {
          final backendInsp = await ApiService.getLatestInspectionForEquipment(sosCode);
          if (backendInsp != null) payload = backendInsp;
        } catch (_) {}
      }
      String inspectorName = inspectorNameController.text.trim();
      if (inspectorName.isEmpty) {
        inspectorName = payload['inspector_name'] ?? 'N/A';
      }
      List<dynamic> answers = payload['answers'] ?? [];
      final pdf = pw.Document();
      pw.MemoryImage? logoImage;
      try {
        final logoBytes = await rootBundle.load('assets/eltrive_logo.jpg');
        logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      } catch (e) {}
      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            buildBackground: (context) {
              return pw.FullPage(
                ignoreMargins: true,
                child: pw.Center(
                  child: pw.Transform.rotate(
                    angle: 0.6,
                    child: pw.Opacity(opacity: 0.12, child: pw.Text("ELTRIVE", style: pw.TextStyle(fontSize: 130, fontWeight: pw.FontWeight.bold))),
                  ),
                ),
              );
            },
          ),
          build: (context) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("INSPECTION REPORT", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                if (logoImage != null) pw.Image(logoImage, width: 75, height: 75),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text("Equipment Details", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Row(children: [pw.SizedBox(width: 120, child: pw.Text("Equipment ID")), pw.Text(": ${reportEquipmentId(eqData, fallback: sosCode)}")]),
            pw.Row(children: [pw.SizedBox(width: 120, child: pw.Text("Location")), pw.Text(": ${reportLocation(eqData, fallback: 'N/A')}")]),
            pw.SizedBox(height: 20),
            pw.Text("Inspector Details", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Row(children: [pw.SizedBox(width: 120, child: pw.Text("Inspector Name")), pw.Text(": $inspectorName")]),
            pw.Row(children: [pw.SizedBox(width: 120, child: pw.Text("SOS Number")), pw.Text(": $sosCode")]),
            pw.Row(children: [pw.SizedBox(width: 120, child: pw.Text("Inspection Date")), pw.Text(": ${DateFormat("dd-MM-yyyy").format(DateTime.now())}")]),
            if (payload['remarks'] != null && payload['remarks'].toString().trim().isNotEmpty)
              pw.Padding(padding: const pw.EdgeInsets.only(top: 4), child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.SizedBox(width: 120, child: pw.Text("Remarks")), pw.Expanded(child: pw.Text(": ${payload['remarks']}"))])),
            pw.SizedBox(height: 20),
            pw.Text("Checklist Results", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            if (answers.isEmpty) pw.Text("No offline checklist found for this equipment.") else ...answers.map((ans) {
              final val = ans['answer'].toString().toLowerCase();
              final isOk = val == 'true' || val == 'yes';
              final isNa = val == 'na';
              final icon = isOk ? '✓ ' : (isNa ? '- ' : '✗ ');
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(icon, style: pw.TextStyle(color: isOk ? PdfColors.green : (isNa ? PdfColors.orange : PdfColors.red))),
                    pw.Expanded(child: pw.Text("${ans['checklist_item_id']}. ${ans['item_text'] ?? 'Item'} : ${ans['answer'] == 'true' || ans['answer'] == true || ans['answer'] == 'YES' ? 'YES' : ans['answer'] == 'false' || ans['answer'] == false || ans['answer'] == 'NO' ? 'NO' : 'N/A'} ${ans['remarks'] != null && ans['remarks'].toString().isNotEmpty ? '(${ans['remarks']})' : ''}")),
                  ]
                )
              );
            }).toList(),
          ],
        ),
      );
      final fileName = "Single_Report_${sosCode}_${DateTime.now().millisecondsSinceEpoch}.pdf";
      if (kIsWeb) {
        WebDownloadHelper.downloadFile(await pdf.save(), fileName);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PDF downloaded ✅")));
        setState(() => loading = false);
        return;
      }
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/$fileName";
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      if (mounted) await OpenFilex.open(path);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => loading = false);
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) => SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: Icon(icon, color: Colors.white), label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18), backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: loading ? null : onTap));

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Reports"),
          backgroundColor: Colors.blue,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Single Report", icon: Icon(Icons.assignment)),
              Tab(text: "Plant Report", icon: Icon(Icons.domain)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: SINGLE REPORT
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text("Single Equipment Report", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),
                          TextField(
                            controller: sosController,
                            decoration: const InputDecoration(labelText: "SOS Number", border: OutlineInputBorder(), prefixIcon: Icon(Icons.qr_code)),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: inspectorNameController,
                            decoration: const InputDecoration(labelText: "Inspector Name (Optional)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                          ),
                          const SizedBox(height: 25),
                          _actionBtn("Generate Single PDF", Icons.picture_as_pdf, Colors.red, generateSinglePDF),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // TAB 2: PLANT REPORT
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(value: selectedPlant, isExpanded: true, items: ["EyeWash"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setState(() => selectedPlant = val!), decoration: const InputDecoration(labelText: "Plant", border: OutlineInputBorder())),
                          const SizedBox(height: 15),
                          DropdownButtonFormField<String>(value: selectedUnit, isExpanded: true, items: ["UNIT-1", "UNIT-2", "UNIT-3"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (val) => setState(() => selectedUnit = val!), decoration: const InputDecoration(labelText: "Unit", border: OutlineInputBorder())),
                          const SizedBox(height: 15),
                          Row(children: [
                            Expanded(child: TextField(controller: startController, readOnly: true, onTap: () => _pickDate(true), decoration: const InputDecoration(labelText: "From Date", border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)))),
                            const SizedBox(width: 10),
                            Expanded(child: TextField(controller: endController, readOnly: true, onTap: () => _pickDate(false), decoration: const InputDecoration(labelText: "To Date", border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)))),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _actionBtn("Generate PDF Report", Icons.picture_as_pdf, Colors.red, generatePDF),
                  const SizedBox(height: 15),
                  _actionBtn("Download Excel Sheet", Icons.table_chart, Colors.green, generateExcel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


}

