import 'package:flutter/material.dart';
import 'package:fire_new/utils/web_download_helper.dart';
import 'package:fire_new/common/report_utils.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'services/apiservice.dart';
import 'local_db.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with SingleTickerProviderStateMixin {
  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();

  String selectedPlant = "Fire Extinguishers";
  String selectedUnit = "UNIT-1";

  bool loading = false;

  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();
  final TextEditingController sosController = TextEditingController();
  final TextEditingController inspectorNameController = TextEditingController();

  late TabController _tabController;

  static const _kNavy = Color(0xFF0D1B2A);
  static const _kAccent = Color(0xFF1565C0);
  static const _kRed = Color(0xFFD32F2F);
  static const _kGreen = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    updateDateFields();
    _prefillLatestInspection();
  }

  @override
  void dispose() {
    _tabController.dispose();
    startController.dispose();
    endController.dispose();
    sosController.dispose();
    inspectorNameController.dispose();
    super.dispose();
  }

  void updateDateFields() {
    startController.text = DateFormat("dd/MM/yyyy").format(startDate);
    endController.text = DateFormat("dd/MM/yyyy").format(endDate);
  }

  Future<void> _prefillLatestInspection() async {
    try {
      // Search ALL modules, not just fire_extinguisher
      final pendingList = await LocalDB.getAllModuleInspections();
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
      debugPrint("Prefill error: $e");
    }
  }

  Future<void> pickDate(bool isStart) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _kAccent),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        isStart ? startDate = picked : endDate = picked;
        updateDateFields();
      });
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchData() async {
    final active = await ApiService.getActive();
    final upcoming = await ApiService.getUpcoming();
    final service = await ApiService.getNeedsService();
    final due = await ApiService.getDueInspection();
    final expired = await ApiService.getExpired();

    return {
      "Active": [...active, ...upcoming],
      "Needs Service": service,
      "Due Inspection": due,
      "Expired": expired,
    };
  }

  Future<void> generatePDF() async {
    setState(() => loading = true);

    try {
      final dataMap = await fetchData();
      List<Map<String, dynamic>> allData = [];
      dataMap.forEach((status, list) {
        allData.addAll(list.map((e) => {...e, "status": status}));
      });

      if (allData.isEmpty) {
        if (mounted) _showSnack("No data to generate PDF", isError: true);
        setState(() => loading = false);
        return;
      }

      pw.MemoryImage? logoImage;
      try {
        final logoBytes = await rootBundle.load('assets/eltrive_logo.jpg');
        logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      } catch (_) {}

      final pdf = await buildPlantReportPDF(
        plantName: selectedPlant,
        unitName: selectedUnit,
        startDate: startDate,
        endDate: endDate,
        allData: allData,
        logoImage: logoImage,
        customTitle: "ELTRIVE PLANT REPORT",
      );

      final fileName = "Report_${DateTime.now().millisecondsSinceEpoch}.pdf";
      if (kIsWeb) {
        WebDownloadHelper.downloadFile(await pdf.save(), fileName);
        if (mounted) _showSnack("PDF downloaded successfully");
        setState(() => loading = false);
        return;
      }
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/$fileName";
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      if (mounted) await OpenFilex.open(path);
    } catch (e) {
      if (mounted) _showSnack("Error generating PDF: $e", isError: true);
    }
    setState(() => loading = false);
  }

  Future<void> downloadExcel() async {
    setState(() => loading = true);
    try {
      final dataMap = await fetchData();
      var excel = Excel.createExcel();
      dataMap.forEach((status, list) {
        Sheet sheet = excel[status];
        sheet.appendRow(["SOS CODE", "LOCATION", "STATUS", "LAST INSPECTION", "NEXT INSPECTION"]);
        for (var item in list) {
          sheet.appendRow([
            reportEquipmentId(item),
            reportLocation(item),
            status,
            reportPreviousInspection(item),
            reportNextInspection(item),
          ]);
        }
      });
      final fileName = "Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      if (kIsWeb) {
        WebDownloadHelper.downloadFile(excel.encode()!, fileName);
        if (mounted) _showSnack("Excel downloaded successfully");
        setState(() => loading = false);
        return;
      }
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/$fileName";
      File file = File(path);
      await file.writeAsBytes(excel.encode()!);
      if (mounted) await OpenFilex.open(path);
    } catch (e) {
      if (mounted) _showSnack("Error generating Excel: $e", isError: true);
    }
    setState(() => loading = false);
  }

  Future<void> generateSinglePDF() async {
    final sosCode = sosController.text.trim();
    if (sosCode.isEmpty) {
      _showSnack("Please enter SOS Number", isError: true);
      return;
    }
    setState(() => loading = true);
    try {
      final eqData = await ApiService.searchAny(sosCode);
      if (eqData == null || eqData.isEmpty) {
        _showSnack("Equipment $sosCode not found", isError: true);
        setState(() => loading = false);
        return;
      }

      Map<String, dynamic> payload = {};

      // PRIMARY: Server is authoritative — data saved there at inspection time.
      // This works 10 days, 1 year, 10 years later regardless of device state.
      try {
        final serverInsp = await ApiService.getLatestInspectionForEquipment(sosCode);
        if (serverInsp != null && serverInsp.isNotEmpty) payload = serverInsp;
      } catch (_) {}

      // FALLBACK: Local SQLite — used only when offline / server unreachable.
      if (payload.isEmpty) {
        final allInspections = await LocalDB.getAllModuleInspections();
        final match = allInspections
            .where((e) => e['equipment_id'].toString().toLowerCase() == sosCode.toLowerCase())
            .toList();
        if (match.isNotEmpty) {
          payload = match.last['payload'] as Map<String, dynamic>;
        }
      }

      String inspectorName = inspectorNameController.text.trim();
      if (inspectorName.isEmpty) {
        inspectorName = payload['inspector_name'] ?? 'N/A';
      }

      pw.MemoryImage? logoImage;
      try {
        final logoBytes = await rootBundle.load('assets/eltrive_logo.jpg');
        logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      } catch (_) {}

      final pdf = await buildSingleInspectionReportPDF(
        eqData: eqData,
        payload: payload,
        sosCode: sosCode,
        inspectorName: inspectorName,
        logoImage: logoImage,
      );
      final fileName = "Single_Report_${sosCode}_${DateTime.now().millisecondsSinceEpoch}.pdf";
      if (kIsWeb) {
        WebDownloadHelper.downloadFile(await pdf.save(), fileName);
        if (mounted) _showSnack("PDF downloaded successfully");
        setState(() => loading = false);
        return;
      }
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/$fileName";
      final file = File(path);
      await file.writeAsBytes(await pdf.save());
      if (mounted) await OpenFilex.open(path);
    } catch (e) {
      if (mounted) _showSnack("Error: $e", isError: true);
    }
    setState(() => loading = false);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: isError ? _kRed : _kGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _kAccent, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCFD8DC))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCFD8DC))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kAccent, width: 2)),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        labelStyle: const TextStyle(color: Color(0xFF607D8B)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      );

  Widget _gradientButton({
    required String label,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: onTap == null ? [Colors.grey.shade400, Colors.grey.shade300] : colors),
          borderRadius: BorderRadius.circular(14),
          boxShadow: onTap == null ? [] : [BoxShadow(color: colors.last.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: ElevatedButton.icon(
          icon: Icon(icon, color: Colors.white, size: 20),
          label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: onTap,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kNavy, _kAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Row(children: [
          Icon(Icons.summarize_rounded, color: Colors.white, size: 22),
          SizedBox(width: 10),
          Text("Reports", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        ]),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "Single Report", icon: Icon(Icons.assignment_ind_rounded, size: 20)),
            Tab(text: "Plant Report", icon: Icon(Icons.domain_rounded, size: 20)),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildSingleReportTab(),
              _buildPlantReportTab(),
            ],
          ),
          if (loading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  SizedBox(height: 16),
                  Text("Generating Report...", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSingleReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Info Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1976D2)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: _kAccent.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, color: Colors.white70, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Enter the SOS number to generate a detailed inspection report for a single equipment unit.",
                style: TextStyle(color: Colors.white, fontSize: 12.5),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        // Form Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionHeader("Equipment Details", Icons.qr_code_scanner_rounded, _kAccent),
            TextField(
              controller: sosController,
              decoration: _inputDecoration("SOS Number / Equipment ID", Icons.qr_code_rounded),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: inspectorNameController,
              decoration: _inputDecoration("Inspector Name (Optional)", Icons.person_rounded),
            ),
            const SizedBox(height: 8),
            const Text(
              "Leave blank to auto-fill from the last recorded inspection.",
              style: TextStyle(fontSize: 11.5, color: Color(0xFF90A4AE)),
            ),
          ]),
        ),
        const SizedBox(height: 28),

        _gradientButton(
          label: "Generate PDF Report",
          icon: Icons.picture_as_pdf_rounded,
          colors: const [Color(0xFFC62828), _kRed],
          onTap: loading ? null : generateSinglePDF,
        ),
        const SizedBox(height: 40),

        // Historical data note
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.history_rounded, size: 18, color: Color(0xFF78909C)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Reports include the most recent inspection data. If the app was reinstalled, historical records are fetched from the server automatically.",
                style: TextStyle(fontSize: 12, color: Color(0xFF546E7A)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildPlantReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Info Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: _kGreen.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: const Row(children: [
            Icon(Icons.factory_rounded, color: Colors.white70, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Generate a complete plant-wide compliance report for all equipment units within a selected date range.",
                style: TextStyle(color: Colors.white, fontSize: 12.5),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        // Filters Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionHeader("Report Filters", Icons.tune_rounded, _kGreen),
            DropdownButtonFormField<String>(
              initialValue: selectedPlant,
              isExpanded: true,
              decoration: _inputDecoration("Plant Category", Icons.local_fire_department_rounded),
              items: ["Fire Extinguishers", "Hose Reel", "Drum Hose Reel"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => selectedPlant = val!),
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedUnit,
              isExpanded: true,
              decoration: _inputDecoration("Facility Unit", Icons.business_rounded),
              items: ["UNIT-1", "UNIT-2", "UNIT-3"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => selectedUnit = val!),
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 20),
            _sectionHeader("Date Range", Icons.date_range_rounded, _kAccent),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: startController,
                  readOnly: true,
                  onTap: () => pickDate(true),
                  decoration: _inputDecoration("From Date", Icons.calendar_today_rounded),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF90A4AE), size: 20),
              ),
              Expanded(
                child: TextField(
                  controller: endController,
                  readOnly: true,
                  onTap: () => pickDate(false),
                  decoration: _inputDecoration("To Date", Icons.event_rounded),
                ),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 28),

        _gradientButton(
          label: "Generate PDF Report",
          icon: Icons.picture_as_pdf_rounded,
          colors: const [Color(0xFFC62828), _kRed],
          onTap: loading ? null : generatePDF,
        ),
        const SizedBox(height: 14),
        _gradientButton(
          label: "Download Excel Sheet",
          icon: Icons.table_chart_rounded,
          colors: const [Color(0xFF1B5E20), _kGreen],
          onTap: loading ? null : downloadExcel,
        ),
        const SizedBox(height: 40),
      ]),
    );
  }
}
