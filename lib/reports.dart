
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/apiservice.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';

import 'dart:io';
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
      await Permission.manageExternalStorage.request();

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

      pdf.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Text("PLANT REPORT",
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),

            pw.SizedBox(height: 10),

            pw.Text("Plant: $selectedPlant"),
            pw.Text("Unit: $selectedUnit"),
            pw.Text(
                "Date: ${DateFormat("dd-MM-yyyy").format(startDate)} to ${DateFormat("dd-MM-yyyy").format(endDate)}"),

            pw.SizedBox(height: 20),

            pw.Text("Summary",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

            pw.Column(
              children: dataMap.entries.map((e) {
                return pw.Text("${e.key}: ${e.value.length}");
              }).toList(),
            ),

            pw.SizedBox(height: 20),

            pw.Table.fromTextArray(
              headers: ["ID", "Equipment", "Status", "Unit"],
              data: allData.map((e) {
                return [
                  (e['id'] ?? '').toString(),
                  (e['equipment_code'] ?? '').toString(),
                  (e['status'] ?? '').toString(),
                  selectedUnit
                ];
              }).toList(),
            ),
          ],
        ),
      );

      final dir = Directory('/storage/emulated/0/Download');
      final file = File(
          "${dir.path}/Report_${DateTime.now().millisecondsSinceEpoch}.pdf");

      await file.writeAsBytes(await pdf.save());

      await OpenFilex.open(file.path);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PDF saved in Downloads")),
      );
    } catch (e) {
      print("PDF ERROR: $e");
    }

    setState(() => loading = false);
  }

  // ================= EXCEL =================
  Future<void> downloadExcel() async {
    setState(() => loading = true);

    try {
      await Permission.manageExternalStorage.request();

      final dataMap = await fetchData();

      var excel = Excel.createExcel();

      dataMap.forEach((status, list) {
        Sheet sheet = excel[status];

        sheet.appendRow(["ID", "Equipment", "Status", "Unit"]);

        for (var item in list) {
          sheet.appendRow([
            item['id'] ?? '',
            item['equipment_code'] ?? '',
            status,
            selectedUnit
          ]);
        }
      });

      Directory dir = Directory('/storage/emulated/0/Download');

      String path =
          "${dir.path}/Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";

      File file = File(path);

      await file.writeAsBytes(excel.encode()!);

      await OpenFilex.open(path);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Excel saved in Downloads")),
      );
    } catch (e) {
      print("EXCEL ERROR: $e");
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

