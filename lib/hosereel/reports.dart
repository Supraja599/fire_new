import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

import 'services/apiservice.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final api = HoseReelApiService();

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  String selectedPlant = "Hose Reel";
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
      if (isStart) {
        startDate = picked;
      } else {
        endDate = picked;
      }
      _updateDateFields();
    });
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchData() async {
    final equipment = await api.getEquipmentList();

    List<Map<String, dynamic>> byStatus(String status) {
      return equipment
          .where((item) => item["status_bucket"]?.toString() == status)
          .toList();
    }

    return {
      "Active": byStatus("active"),
      "Needs Service": byStatus("needs-service"),
      "Due Inspection": byStatus("due-inspection"),
      "Expired": byStatus("expired"),
    };
  }

  Future<void> _generatePdf() async {
    setState(() => loading = true);

    try {
      await Permission.manageExternalStorage.request();
      final dataMap = await _fetchData();

      final allData = <Map<String, dynamic>>[];
      dataMap.forEach((status, list) {
        allData.addAll(list.map((item) => {...item, "status": status}));
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
            pw.Text(
              "PLANT REPORT",
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text("Plant: $selectedPlant"),
            pw.Text("Unit: $selectedUnit"),
            pw.Text(
              "Date: ${DateFormat("dd-MM-yyyy").format(startDate)} to ${DateFormat("dd-MM-yyyy").format(endDate)}",
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              "Summary",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Column(
              children: dataMap.entries.map((entry) {
                return pw.Text("${entry.key}: ${entry.value.length}");
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ["SOS Code", "Location", "Status", "Unit"],
              data: allData.map((item) {
                return [
                  (item["sos_code"] ?? item["id"] ?? "").toString(),
                  (item["location_name"] ?? item["building_name"] ?? "")
                      .toString(),
                  (item["status"] ?? "").toString(),
                  selectedUnit,
                ];
              }).toList(),
            ),
          ],
        ),
      );

      final dir = Directory('/storage/emulated/0/Download');
      final file = File(
        "${dir.path}/HoseReel_Report_${DateTime.now().millisecondsSinceEpoch}.pdf",
      );

      await file.writeAsBytes(await pdf.save());
      await OpenFilex.open(file.path);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PDF saved in Downloads")),
      );
    } catch (e) {
      debugPrint("PDF ERROR: $e");
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> _downloadExcel() async {
    setState(() => loading = true);

    try {
      await Permission.manageExternalStorage.request();
      final dataMap = await _fetchData();
      final excel = Excel.createExcel();

      dataMap.forEach((status, list) {
        final sheet = excel[status];
        sheet.appendRow(["SOS Code", "Location", "Status", "Unit"]);

        for (final item in list) {
          sheet.appendRow([
            item["sos_code"] ?? item["id"] ?? "",
            item["location_name"] ?? item["building_name"] ?? "",
            status,
            selectedUnit,
          ]);
        }
      });

      final dir = Directory('/storage/emulated/0/Download');
      final path =
          "${dir.path}/HoseReel_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";

      final file = File(path);
      await file.writeAsBytes(excel.encode()!);
      await OpenFilex.open(path);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Excel saved in Downloads")),
      );
    } catch (e) {
      debugPrint("EXCEL ERROR: $e");
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    startController.dispose();
    endController.dispose();
    super.dispose();
  }

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
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedPlant,
                      isExpanded: true,
                      items: const ["Hose Reel"]
                          .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedPlant = value!),
                      decoration: const InputDecoration(
                        labelText: "Plant",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedUnit,
                      isExpanded: true,
                      items: const ["UNIT-1", "UNIT-2", "UNIT-3"]
                          .map((item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedUnit = value!),
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
                            onTap: () => _pickDate(true),
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
                            onTap: () => _pickDate(false),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Generate PDF"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: loading ? null : _generatePdf,
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: loading ? null : _downloadExcel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
