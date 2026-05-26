import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hive/hive.dart';
import 'package:fire_new/common/report_utils.dart';
import 'package:fire_new/guided_capture_wizard.dart';
import 'package:fire_new/local_db.dart';
import 'package:fire_new/services/apiservice.dart';
import 'package:fire_new/utils/web_download_helper.dart';

/// Shared reports page used by every module.
/// Server is always queried first for inspection payload — works 10 days,
/// 1 year, or 10 years after the inspection was submitted.
/// Local SQLite is the offline fallback only.
class ModuleReportsPage extends StatefulWidget {
  final String moduleName;
  final String moduleCode;
  final Future<List<Map<String, dynamic>>> Function() getEquipmentList;
  final Future<Map<String, dynamic>?> Function(String sosCode) getEquipmentByQuery;

  const ModuleReportsPage({
    super.key,
    required this.moduleName,
    required this.moduleCode,
    required this.getEquipmentList,
    required this.getEquipmentByQuery,
  });

  @override
  State<ModuleReportsPage> createState() => _ModuleReportsPageState();
}

class _ModuleReportsPageState extends State<ModuleReportsPage>
    with SingleTickerProviderStateMixin {
  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();
  String selectedUnit = "UNIT-1";
  bool loading = false;

  final TextEditingController sosController = TextEditingController();
  final TextEditingController inspectorNameController = TextEditingController();
  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();

  late TabController _tabController;

  static const _kNavy = Color(0xFF0D1B2A);
  static const _kAccent = Color(0xFF1565C0);
  static const _kRed = Color(0xFFD32F2F);
  static const _kGreen = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _updateDateFields();
    _prefillLatestInspection();
  }

  @override
  void dispose() {
    _tabController.dispose();
    sosController.dispose();
    inspectorNameController.dispose();
    startController.dispose();
    endController.dispose();
    super.dispose();
  }

  void _updateDateFields() {
    startController.text = DateFormat("dd/MM/yyyy").format(startDate);
    endController.text = DateFormat("dd/MM/yyyy").format(endDate);
  }

  Future<void> _prefillLatestInspection() async {
    try {
      final box = Hive.isBoxOpen('inspectionBox') ? Hive.box<dynamic>('inspectionBox') : null;
      if (box != null) {
        final hiveEqId = box.get('last_equipment_id_${widget.moduleCode}')?.toString() ??
                         box.get('last_equipment_id')?.toString();
        final hiveInspector = box.get('last_inspector_name_${widget.moduleCode}')?.toString() ??
                             box.get('last_inspector_name')?.toString();
        if (hiveEqId != null && hiveEqId.isNotEmpty) {
          setState(() {
            sosController.text = hiveEqId;
            if (hiveInspector != null && hiveInspector.isNotEmpty) {
              inspectorNameController.text = hiveInspector;
            }
          });
          return;
        }
      }

      final list = await LocalDB.getAllModuleInspections(moduleCode: widget.moduleCode);
      if (list.isNotEmpty && mounted) {
        final last = list.last;
        final payload = last['payload'] as Map<String, dynamic>?;
        setState(() {
          sosController.text = last['equipment_id']?.toString() ?? '';
          inspectorNameController.text = payload?['inspector_name']?.toString() ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _scanQRCode() async {
    if (kIsWeb) {
      _showSnack("QR scanner not available on web. Please type the SOS number.", isError: true);
      return;
    }
    final MobileScannerController scanCtrl = MobileScannerController();
    bool scanned = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Color(0xFF0D1B2A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          const Text("SCAN EQUIPMENT QR CODE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 13)),
          const SizedBox(height: 6),
          const Text("Point camera at the equipment barcode or QR tag", style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(
                  controller: scanCtrl,
                  onDetect: (capture) {
                    if (scanned) return;
                    final raw = capture.barcodes.firstOrNull?.rawValue;
                    if (raw == null || raw.isEmpty) return;
                    scanned = true;
                    setState(() => sosController.text = raw.trim());
                    scanCtrl.dispose();
                    Navigator.pop(context);
                    _showSnack("SOS scanned: ${raw.trim()}");
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: TextButton.icon(
              onPressed: () { scanCtrl.dispose(); Navigator.pop(context); },
              icon: const Icon(Icons.close, color: Colors.white54),
              label: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
          ),
        ]),
      ),
    );
    if (!scanned) scanCtrl.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
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
        _updateDateFields();
      });
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchEquipmentByStatus() async {
    final equipment = await widget.getEquipmentList();
    List<Map<String, dynamic>> byBucket(String bucket) {
      if (bucket == "active") {
        return equipment
            .where((e) =>
                e["status_bucket"]?.toString() == "active" ||
                e["status_bucket"]?.toString() == "upcoming")
            .toList();
      }
      return equipment.where((e) => e["status_bucket"]?.toString() == bucket).toList();
    }

    return {
      "Active": byBucket("active"),
      "Needs Service": byBucket("needs-service"),
      "Due Inspection": byBucket("due-inspection"),
      "Expired": byBucket("expired"),
    };
  }

  // ─── Plant Report PDF ───────────────────────────────────────────────────────

  Future<void> _generatePlantPDF() async {
    setState(() => loading = true);
    try {
      final dataMap = await _fetchEquipmentByStatus();
      final allData = <Map<String, dynamic>>[];
      dataMap.forEach((k, v) => allData.addAll(v.map((e) => {...e, "status": k, "status_label": k})));

      if (allData.isEmpty) {
        if (mounted) _showSnack("No data found", isError: true);
        setState(() => loading = false);
        return;
      }

      pw.MemoryImage? logoImage;
      try {
        final bytes = await rootBundle.load('assets/eltrive_logo.webp');
        logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
      } catch (_) {}

      final pdf = await buildPlantReportPDF(
        plantName: widget.moduleName,
        unitName: selectedUnit,
        startDate: startDate,
        endDate: endDate,
        allData: allData,
        logoImage: logoImage,
        customTitle: "ELTRIVE ${widget.moduleName.toUpperCase()} REPORT",
      );

      final fileName =
          "${widget.moduleName.replaceAll(' ', '_')}_Report_${DateTime.now().millisecondsSinceEpoch}.pdf";

      if (kIsWeb) {
        WebDownloadHelper.downloadFile(await pdf.save(), fileName);
        if (mounted) _showSnack("PDF downloaded successfully");
        setState(() => loading = false);
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final path = "${dir.path}/$fileName";
      await File(path).writeAsBytes(await pdf.save());
      if (mounted) await OpenFilex.open(path);
    } catch (e) {
      if (mounted) _showSnack("Error: $e", isError: true);
    }
    setState(() => loading = false);
  }

  // ─── Plant Report Excel ─────────────────────────────────────────────────────

  Future<void> _downloadExcel() async {
    setState(() => loading = true);
    try {
      final dataMap = await _fetchEquipmentByStatus();
      final excel = Excel.createExcel();
      dataMap.forEach((status, list) {
        final sheet = excel[status];
        sheet.appendRow(["SOS CODE", "LOCATION", "STATUS", "LAST INSPECTION", "NEXT INSPECTION"]);
        for (final item in list) {
          sheet.appendRow([
            reportEquipmentId(item),
            reportLocation(item),
            status,
            reportPreviousInspection(item),
            reportNextInspection(item),
          ]);
        }
      });

      final fileName =
          "${widget.moduleName.replaceAll(' ', '_')}_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx";

      if (kIsWeb) {
        WebDownloadHelper.downloadFile(excel.encode()!, fileName);
        if (mounted) _showSnack("Excel downloaded successfully");
        setState(() => loading = false);
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final path = "${dir.path}/$fileName";
      await File(path).writeAsBytes(excel.encode()!);
      if (mounted) await OpenFilex.open(path);
    } catch (e) {
      if (mounted) _showSnack("Error: $e", isError: true);
    }
    setState(() => loading = false);
  }

  // ─── Single Equipment PDF ───────────────────────────────────────────────────

  Future<void> _generateSinglePDF() async {
    final sosCode = sosController.text.trim();
    if (sosCode.isEmpty) {
      _showSnack("Please enter SOS Number", isError: true);
      return;
    }
    setState(() => loading = true);
    try {
      final eqData = await widget.getEquipmentByQuery(sosCode);
      if (eqData == null || eqData.isEmpty) {
        _showSnack("Equipment $sosCode not found", isError: true);
        setState(() => loading = false);
        return;
      }

      Map<String, dynamic> payload = {};

      // PRIMARY: Server — authoritative source, stores data permanently.
      // Works 10 days, 1 year, or 10 years after the inspection.
      try {
        final serverInsp = await ApiService.getLatestInspectionForEquipment(sosCode);
        if (serverInsp != null && serverInsp.isNotEmpty) payload = serverInsp;
      } catch (_) {}

      // FALLBACK: Local SQLite — offline use only.
      if (payload.isEmpty) {
        final all = await LocalDB.getAllModuleInspections(moduleCode: widget.moduleCode);
        final match = all
            .where((e) => e['equipment_id'].toString().toLowerCase() == sosCode.toLowerCase())
            .toList();
        if (match.isNotEmpty) {
          payload = match.last['payload'] as Map<String, dynamic>;
        }
      }

      String inspectorName = inspectorNameController.text.trim();
      if (inspectorName.isEmpty) inspectorName = payload['inspector_name'] ?? 'N/A';

      pw.MemoryImage? logoImage;
      try {
        final bytes = await rootBundle.load('assets/eltrive_logo.webp');
        logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
      } catch (_) {}

      final pdf = await buildSingleInspectionReportPDF(
        eqData: eqData,
        payload: payload,
        sosCode: sosCode,
        inspectorName: inspectorName,
        logoImage: logoImage,
        moduleCode: widget.moduleCode,
        capturedImagesBase64: GuidedCaptureWizardPage.latestCapturedImagesBase64,
      );

      final fileName = "Single_Report_${sosCode}_${DateTime.now().millisecondsSinceEpoch}.pdf";

      if (kIsWeb) {
        WebDownloadHelper.downloadFile(await pdf.save(), fileName);
        if (mounted) _showSnack("PDF downloaded successfully");
        setState(() => loading = false);
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final path = "${dir.path}/$fileName";
      await File(path).writeAsBytes(await pdf.save());
      if (mounted) await OpenFilex.open(path);
    } catch (e) {
      if (mounted) _showSnack("Error: $e", isError: true);
    }
    setState(() => loading = false);
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: isError ? _kRed : _kGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  InputDecoration _inputDec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _kAccent, size: 20),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCFD8DC))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCFD8DC))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kAccent, width: 2)),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        labelStyle: const TextStyle(color: Color(0xFF607D8B)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      );

  Widget _gradientBtn({
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
          gradient: LinearGradient(
              colors: onTap == null
                  ? [Colors.grey.shade400, Colors.grey.shade300]
                  : colors),
          borderRadius: BorderRadius.circular(14),
          boxShadow: onTap == null
              ? []
              : [
                  BoxShadow(
                      color: colors.last.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
        ),
        child: ElevatedButton.icon(
          icon: Icon(icon, color: Colors.white, size: 20),
          label: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.5)),
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
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(title,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ]),
      );

  // ─── Build ──────────────────────────────────────────────────────────────────

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
        title: Row(children: [
          const Icon(Icons.summarize_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Text("${widget.moduleName} Reports",
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
        ]),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "Single Report", icon: Icon(Icons.assignment_ind_rounded, size: 20)),
            Tab(text: "Plant Report", icon: Icon(Icons.domain_rounded, size: 20)),
          ],
        ),
      ),
      body: Stack(children: [
        TabBarView(
          controller: _tabController,
          children: [_buildSingleTab(), _buildPlantTab()],
        ),
        if (loading)
          Container(
            color: Colors.black45,
            child: const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                SizedBox(height: 16),
                Text("Generating Report...",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _buildSingleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Info banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: _kAccent.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Enter the SOS number to generate a detailed inspection report for a single ${widget.moduleName} unit.",
                style: const TextStyle(color: Colors.white, fontSize: 12.5),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        // Form card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4))
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionHeader("Equipment Details", Icons.qr_code_scanner_rounded, _kAccent),
            TextField(
              controller: sosController,
              decoration: _inputDec("SOS Number / Equipment ID", Icons.qr_code_rounded).copyWith(
                suffixIcon: IconButton(
                  tooltip: "Scan QR / Barcode",
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF1565C0)),
                  onPressed: _scanQRCode,
                ),
              ),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: inspectorNameController,
              decoration: _inputDec("Inspector Name (Optional)", Icons.person_rounded),
            ),
            const SizedBox(height: 8),
            const Text(
              "Leave blank to auto-fill from the last recorded inspection.",
              style: TextStyle(fontSize: 11.5, color: Color(0xFF90A4AE)),
            ),
          ]),
        ),
        const SizedBox(height: 28),

        _gradientBtn(
          label: "Generate PDF Report",
          icon: Icons.picture_as_pdf_rounded,
          colors: const [Color(0xFFC62828), _kRed],
          onTap: loading ? null : _generateSinglePDF,
        ),
        const SizedBox(height: 40),

        // Historical note
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
                "Reports always fetch the latest data from the server — works 10 days, 1 year, or 10 years after the inspection was submitted. Local device data is used only when offline.",
                style: TextStyle(fontSize: 12, color: Color(0xFF546E7A)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildPlantTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Info banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: _kGreen.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(children: [
            const Icon(Icons.factory_rounded, color: Colors.white70, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Generate a complete ${widget.moduleName} compliance report for all units within a selected date range.",
                style: const TextStyle(color: Colors.white, fontSize: 12.5),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),

        // Filters card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4))
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionHeader("Report Filters", Icons.tune_rounded, _kGreen),

            // Module name (read-only label)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCFD8DC)),
              ),
              child: Row(children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: _kAccent, size: 20),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Module",
                      style: TextStyle(fontSize: 11, color: Color(0xFF607D8B))),
                  const SizedBox(height: 2),
                  Text(widget.moduleName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ]),
              ]),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: selectedUnit,
              isExpanded: true,
              decoration: _inputDec("Facility Unit", Icons.business_rounded),
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
                  onTap: () => _pickDate(true),
                  decoration: _inputDec("From Date", Icons.calendar_today_rounded),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                child: const Icon(Icons.arrow_forward_rounded,
                    color: Color(0xFF90A4AE), size: 20),
              ),
              Expanded(
                child: TextField(
                  controller: endController,
                  readOnly: true,
                  onTap: () => _pickDate(false),
                  decoration: _inputDec("To Date", Icons.event_rounded),
                ),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 28),

        _gradientBtn(
          label: "Generate PDF Report",
          icon: Icons.picture_as_pdf_rounded,
          colors: const [Color(0xFFC62828), _kRed],
          onTap: loading ? null : _generatePlantPDF,
        ),
        const SizedBox(height: 14),
        _gradientBtn(
          label: "Download Excel Sheet",
          icon: Icons.table_chart_rounded,
          colors: const [Color(0xFF1B5E20), _kGreen],
          onTap: loading ? null : _downloadExcel,
        ),
        const SizedBox(height: 40),
      ]),
    );
  }
}
