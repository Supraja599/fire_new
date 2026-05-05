import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'services/alarm_panel_api_service.dart';

class AlarmPanelReportsPage extends StatefulWidget {
  const AlarmPanelReportsPage({super.key});

  @override
  State<AlarmPanelReportsPage> createState() => _AlarmPanelReportsPageState();
}

class _AlarmPanelReportsPageState extends State<AlarmPanelReportsPage> {
  final api = AlarmPanelApiService();
  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();

  String selectedPlant = "Fire Alarm Panels";
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

  Future pickDate(bool isStart) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) startDate = picked; else endDate = picked;
        updateDateFields();
      });
    }
  }

  Future<void> generatePDF() async {
    setState(() => loading = true);
    try {
      await Permission.manageExternalStorage.request();
      final equipment = await api.getEquipmentList();
      
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Header(level: 0, child: pw.Text("ALARM PANEL STATUS REPORT", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 10),
            pw.Text("Generated on: ${DateFormat("dd-MM-yyyy HH:mm").format(DateTime.now())}"),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ["SOS ID", "Location", "Status", "Last Insp."],
              data: equipment.map((e) => [
                (e["sos_code"] ?? e["id"] ?? "-").toString(),
                (e["location_name"] ?? "-").toString(),
                (e["status"] ?? "-").toString(),
                (e["last_inspection_date"] ?? "-").toString(),
              ]).toList(),
            ),
          ],
        ),
      );

      final dir = Directory('/storage/emulated/0/Download');
      final path = "${dir.path}/Panel_Report_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      await OpenFilex.open(path);
    } catch (e) {
      debugPrint("PDF ERR: $e");
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE8E8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text("Export Reports", style: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFFB71C1C)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.05), blurRadius: 20)]),
              child: Column(
                children: [
                  const Text("Report Configuration", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFB71C1C))),
                  const SizedBox(height: 25),
                  _datePick("From Date", startController, () => pickDate(true)),
                  const SizedBox(height: 15),
                  _datePick("To Date", endController, () => pickDate(false)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _actionButton("GENERATE PDF", Icons.picture_as_pdf, Colors.red.shade900, generatePDF),
            const SizedBox(height: 15),
            _actionButton("DOWNLOAD EXCEL", Icons.table_chart, Colors.green.shade700, () {}),
          ],
        ),
      ),
    );
  }

  Widget _datePick(String label, TextEditingController controller, VoidCallback onTap) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_month, color: Colors.red),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.red.withOpacity(0.02),
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 5,
          shadowColor: color.withOpacity(0.3),
        ),
      ),
    );
  }
}
