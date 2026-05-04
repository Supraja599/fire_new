import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

import 'services/hydrant_api_service.dart';

class HydrantReportsPage extends StatefulWidget {
  const HydrantReportsPage({super.key});

  @override
  State<HydrantReportsPage> createState() => _HydrantReportsPageState();
}

class _HydrantReportsPageState extends State<HydrantReportsPage> {
  final api = HydrantApiService();
  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();
  bool loading = false;
  String selectedUnit = "UNIT-1";

  Future<void> _pick(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        startDate = picked;
      } else {
        endDate = picked;
      }
    });
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchData() async {
    final equipment = await api.getEquipmentList();
    List<Map<String, dynamic>> byStatus(String status) => equipment
        .where((item) => item["status_bucket"]?.toString() == status)
        .toList();

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

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Text(
              "HYDRANT REPORT",
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text("Plant: Hydrant Point"),
            pw.Text("Unit: $selectedUnit"),
            pw.Text(
              "Date: ${DateFormat("dd-MM-yyyy").format(startDate)} to ${DateFormat("dd-MM-yyyy").format(endDate)}",
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ["SOS Code", "Location", "Status", "Unit"],
              data: allData.map((item) {
                return [
                  (item["sos_code"] ?? item["id"] ?? "").toString(),
                  (item["location_name"] ?? item["building_name"] ?? "").toString(),
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
        "${dir.path}/Hydrant_Report_${DateTime.now().millisecondsSinceEpoch}.pdf",
      );
      await file.writeAsBytes(await pdf.save());
      await OpenFilex.open(file.path);
    } catch (_) {}
    if (mounted) setState(() => loading = false);
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
          "${dir.path}/Hydrant_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final file = File(path);
      await file.writeAsBytes(excel.encode()!);
      await OpenFilex.open(path);
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Hydrant Reports"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8E1C1C), Color(0xFFD84315)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Text(
                "Generate hydrant inspection and readiness reports",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _field(
              "From Date",
              DateFormat("dd/MM/yyyy").format(startDate),
              Icons.date_range,
              () => _pick(true),
            ),
            const SizedBox(height: 12),
            _field(
              "To Date",
              DateFormat("dd/MM/yyyy").format(endDate),
              Icons.calendar_month,
              () => _pick(false),
            ),
            const SizedBox(height: 18),
            _field("Plant", "Hydrant Point", Icons.fire_hydrant_alt, null),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: DropdownButtonFormField<String>(
                value: selectedUnit,
                items: const ["UNIT-1", "UNIT-2", "UNIT-3"]
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => selectedUnit = value!),
                decoration: const InputDecoration(
                  labelText: "Unit",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: loading ? null : _generatePdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Generate PDF"),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: loading ? null : _downloadExcel,
                icon: const Icon(Icons.table_chart),
                label: const Text("Download Excel"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String value, IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFC62828)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
