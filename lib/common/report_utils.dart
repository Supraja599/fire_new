/// Utility functions for report pages
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:fire_new/local_db.dart';

/// Asset path for each module's equipment image, shown in the PDF report.
const Map<String, String> _moduleAssetPaths = {
  'fire_extinguisher': 'assets/extinguisher.png',
  'hose_reel':         'assets/hosereel.png',
  'fire_alarm':        'assets/alarm_panel.png',
  'smoke_detector':    'assets/smoke_detector.png',
  'heat_detector':     'assets/heat_detector.png',
  'co_detector':       'assets/co_detector.png',
  'suppression_system':'assets/co2_system.png',
  'safety_shower':     'assets/emergency_shower.png',
  'eyewash_station':   'assets/eye_wash.png',
  'fire_blanket':      'assets/fire_blankets.png',
  'ppe_station':       'assets/ppe_cabinets.png',
  'spill_kit':         'assets/spill_kits.png',
  'fire_trolley':      'assets/fire_trolley.png',
  'ambulance':         'assets/ambulance.png',
  'hydrant':           'assets/firehydrant.png',
  'sprinkler':         'assets/sprinkler.png',
  'fire_door':         'assets/fire_door.png',
  'exit_sign':         'assets/emergency_exit.png',
  'signage':           'assets/signage.png',
  'muster_point':      'assets/muster_points.png',
  'emergency_light':   'assets/emergency_lighting.png',
  'scba_unit':         'assets/scba_unit.png',
  'first_aid_kit':     'assets/first_aid.png',
  'emergency_comm':    'assets/emergency_comm.png',
  'pa_system':         'assets/pa_system.png',
  'wind_sock':         'assets/wind_sock.png',
};

/// Ensures that the selected value for a DropdownButton is present in the list of items.
/// If the selected value is null or not in the list, the first item from [items] is returned.
/// This prevents runtime errors caused by mismatched Dropdown values.
T? ensureDropdownValue<T>(T? selected, List<T> items) {
  if (selected != null && items.contains(selected)) {
    return selected;
  }
  return items.isNotEmpty ? items.first : null;
}

String _firstNonEmptyValue(Map<String, dynamic> item, List<String> keys, {String fallback = "-"}) {
  for (final key in keys) {
    final value = item[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != "null") {
      return text;
    }
  }
  return fallback;
}

String reportEquipmentId(Map<String, dynamic> item, {String fallback = "-"}) {
  return _firstNonEmptyValue(
    item,
    ["sos_code", "equipment_id", "serial_number", "asset_code", "tag_number", "id"],
    fallback: fallback,
  );
}

String reportLocation(Map<String, dynamic> item, {String fallback = "-"}) {
  return _firstNonEmptyValue(
    item,
    [
      "location_name",
      "building_name",
      "zone_name",
      "area_name",
      "area",
      "location",
      "site_name",
      "department_name",
      "plant_name",
    ],
    fallback: fallback,
  );
}

String reportPreviousInspection(Map<String, dynamic> item, {String fallback = "-"}) {
  return _firstNonEmptyValue(
    item,
    [
      "last_inspection_date",
      "last_service_date",
      "last_service",
      "last_inspected",
      "last_inspected_at",
      "inspected_date",
      "inspection_date",
      "updated_at",
      "previous_inspection",
      "previous_inspection_date",
      "last_checked_at",
      "last_maintenance_date",
    ],
    fallback: fallback,
  );
}

String reportNextInspection(Map<String, dynamic> item, {String fallback = "-"}) {
  return _firstNonEmptyValue(
    item,
    [
      "next_inspection_due",
      "next_due_date",
      "next_service_date",
      "due_date",
      "inspection_due_date",
      "expiry_date",
    ],
    fallback: fallback,
  );
}

String reportStatus(Map<String, dynamic> item, {String fallback = "-"}) {
  return _firstNonEmptyValue(
    item,
    ["status_label", "status_bucket", "operational_status", "status", "condition"],
    fallback: fallback,
  );
}

String _normalizeStatus(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll("_", " ")
      .replaceAll("-", " ")
      .replaceAll(RegExp(r"\s+"), " ");
}

bool matchesReportStatus(Map<String, dynamic> item, String statusLabel) {
  final normalizedTarget = _normalizeStatus(statusLabel);
  final normalizedItem = _normalizeStatus(reportStatus(item, fallback: ""));

  if (normalizedItem.isEmpty) return false;
  if (normalizedItem == normalizedTarget) return true;

  const aliases = {
    "needs service": {"need service", "needs service", "needs servicing"},
    "due inspection": {"due inspection", "inspection due"},
    "active": {"active", "ok", "operational", "upcoming"},
    "expired": {"expired", "overdue"},
  };

  final targetAliases = aliases[normalizedTarget];
  if (targetAliases == null) {
    return normalizedItem.contains(normalizedTarget);
  }

  return targetAliases.contains(normalizedItem);
}

String _resolveInspectionDate(Map<String, dynamic> payload) {
  for (final key in ["inspection_date", "inspected_at", "inspected_on", "date", "created_at"]) {
    final val = payload[key]?.toString().trim();
    if (val != null && val.isNotEmpty && val.toLowerCase() != "null") {
      try {
        final dt = DateTime.parse(val);
        return DateFormat("dd-MM-yyyy").format(dt);
      } catch (_) {
        return val;
      }
    }
  }
  return DateFormat("dd-MM-yyyy").format(DateTime.now());
}

Future<pw.Document> buildSingleInspectionReportPDF({
  required Map<String, dynamic> eqData,
  required Map<String, dynamic> payload,
  required String sosCode,
  required String inspectorName,
  pw.MemoryImage? logoImage,
  String? moduleCode,
  List<String>? capturedImagesBase64,
}) async {
  final pdf = pw.Document();
  final answers = (payload['answers'] as List?) ?? [];

  // ── Load module equipment image ──────────────────────────────────────────
  pw.MemoryImage? equipmentImage;
  final String? assetPath = moduleCode != null ? _moduleAssetPaths[moduleCode] : null;
  if (assetPath != null) {
    try {
      final bytes = await rootBundle.load(assetPath);
      equipmentImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}
  }
  if (equipmentImage == null) {
    try {
      final bytes = await rootBundle.load('assets/extinguisher.png');
      equipmentImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}
  }

  // ── Decode captured inspection photos ────────────────────────────────────
  final List<pw.MemoryImage> attachments = [];
  if (capturedImagesBase64 != null) {
    for (final b64 in capturedImagesBase64) {
      try {
        attachments.add(pw.MemoryImage(base64Decode(b64)));
      } catch (_) {}
    }
  }
  const List<String> attachmentLabels = ['OVERALL VIEW', 'BARCODE / TAG', 'COMPONENT DETAIL', 'SURROUNDINGS'];

  // ── Stats ────────────────────────────────────────────────────────────────
  final int total  = answers.length;
  final int passed = answers.where((a) { final v = a['answer']?.toString().toLowerCase() ?? ''; return v == 'true' || v == 'yes'; }).length;
  final int failed = answers.where((a) { final v = a['answer']?.toString().toLowerCase() ?? ''; return v == 'false' || v == 'no'; }).length;
  final int naCount= answers.where((a) { final v = a['answer']?.toString().toLowerCase() ?? ''; return v == 'na'; }).length;
  final int pct    = total > 0 ? ((passed / total) * 100).round() : 0;
  final bool isCompleted = answers.isNotEmpty;

  // ── Load full checklist from SQLite ──────────────────────────────────────
  List<Map<String, dynamic>> allChecklist = [];
  try {
    final resolved = moduleCode ?? (await LocalDB.findEquipmentModuleAndData(sosCode))?['module_code'];
    if (resolved != null) {
      allChecklist = await LocalDB.getModuleRecords(moduleCode: resolved, recordType: 'checklist');
    }
  } catch (_) {}

  // ── Shared header widget ─────────────────────────────────────────────────
  pw.Widget _header() => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: const pw.BoxDecoration(
      color: PdfColor.fromInt(0xFF0D1B2A),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text("INSPECTION REPORT",
              style: pw.TextStyle(color: PdfColors.white, fontSize: 15, fontWeight: pw.FontWeight.bold, letterSpacing: 1.5)),
          pw.SizedBox(height: 3),
          pw.Text("Eltrive Safety & Compliance System",
              style: const pw.TextStyle(color: PdfColors.blueGrey100, fontSize: 8)),
        ]),
        if (logoImage != null)
          pw.Container(
            width: 38, height: 38,
            decoration: const pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.all(pw.Radius.circular(4))),
            padding: const pw.EdgeInsets.all(3),
            child: pw.Image(logoImage),
          ),
      ],
    ),
  );

  // ── Stat box ─────────────────────────────────────────────────────────────
  pw.Widget _statBox(String label, String value, PdfColor bg, PdfColor textColor) =>
    pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 3),
        padding: const pw.EdgeInsets.symmetric(vertical: 10),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0), width: 0.8),
        ),
        child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
          pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: textColor)),
          pw.SizedBox(height: 3),
          pw.Text(label, style: pw.TextStyle(fontSize: 7.5, color: PdfColor.fromInt(0xFF64748B), fontWeight: pw.FontWeight.bold)),
        ]),
      ),
    );

  // ── Build checklist table rows — NO per-row remarks, only overall at bottom ──
  List<pw.TableRow> _buildRows() {
    final rows = <pw.TableRow>[];
    // Header — 3 columns only: # | QUESTION | STATUS
    rows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E3A8A)),
      children: [
        _tCell("#", bold: true, color: PdfColors.white, center: true),
        _tCell("CHECKLIST QUESTION / DESCRIPTION", bold: true, color: PdfColors.white),
        _tCell("STATUS", bold: true, color: PdfColors.white, center: true),
      ],
    ));

    final source = allChecklist.isNotEmpty
        ? allChecklist
        : answers.map((a) => a as Map<String, dynamic>).toList();

    for (int i = 0; i < source.length; i++) {
      final item = source[i];
      Map<String, dynamic>? ans;

      if (allChecklist.isNotEmpty) {
        final targetId = item['id']?.toString().trim().toLowerCase();
        if (targetId != null) {
          for (final a in answers) {
            if (a is Map && a['checklist_item_id']?.toString().trim().toLowerCase() == targetId) {
              ans = Map<String, dynamic>.from(a); break;
            }
          }
        }
      } else {
        ans = item;
      }

      final qText = item['item_text'] ?? item['item'] ?? item['question'] ?? 'Item ${i + 1}';
      final rowBg = i % 2 == 0 ? PdfColors.white : PdfColor.fromInt(0xFFF8FAFC);

      PdfColor badgeBg, badgeBorder, badgeText;
      String label;
      if (ans != null) {
        final v = ans['answer']?.toString().toLowerCase() ?? '';
        final ok = v == 'true' || v == 'yes';
        final na = v == 'na';
        badgeBg     = ok ? PdfColor.fromInt(0xFFDCFCE7) : (na ? PdfColor.fromInt(0xFFF1F5F9) : PdfColor.fromInt(0xFFFEE2E2));
        badgeBorder = ok ? PdfColor.fromInt(0xFF86EFAC) : (na ? PdfColor.fromInt(0xFFCBD5E1) : PdfColor.fromInt(0xFFFCA5A5));
        badgeText   = ok ? PdfColor.fromInt(0xFF15803D) : (na ? PdfColor.fromInt(0xFF475569) : PdfColor.fromInt(0xFFB91C1C));
        label       = ok ? 'YES' : (na ? 'N/A' : 'NO');
      } else {
        badgeBg = badgeBorder = PdfColor.fromInt(0xFFF1F5F9);
        badgeText = PdfColor.fromInt(0xFF94A3B8);
        label = '-';
      }

      rows.add(pw.TableRow(
        decoration: pw.BoxDecoration(color: rowBg),
        children: [
          _tCell((i + 1).toString(), center: true),
          _tCell(qText),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 5),
            child: pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: badgeBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                  border: pw.Border.all(color: badgeBorder, width: 0.5),
                ),
                child: pw.Text(label,
                    style: pw.TextStyle(color: badgeText, fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
              ),
            ),
          ),
        ],
      ));
    }

    if (source.isEmpty) {
      rows.add(pw.TableRow(children: [
        _tCell(''),
        _tCell('No checklist data available.', italic: true),
        _tCell(''),
      ]));
    }
    return rows;
  }

  pw.Widget _checklistTable() {
    final rows = _buildRows();
    return pw.Table(
      columnWidths: const {
        0: pw.FixedColumnWidth(22),
        1: pw.FlexColumnWidth(),
        2: pw.FixedColumnWidth(55),
      },
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE2E8F0), width: 0.6),
      children: rows,
    );
  }

  // ── PAGE 1: Main report ───────────────────────────────────────────────────
  pdf.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(0),
    header: (_) => _header(),
    footer: (ctx) => pw.Container(
      color: PdfColor.fromInt(0xFF0D1B2A),
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text("Report ID: $sosCode-${DateFormat('ddMMyyyy').format(DateTime.now())}",
            style: const pw.TextStyle(color: PdfColors.blueGrey100, fontSize: 7)),
        pw.Text("Page ${ctx.pageNumber} of ${ctx.pagesCount}",
            style: const pw.TextStyle(color: PdfColors.blueGrey100, fontSize: 7)),
      ]),
    ),
    build: (ctx) => [
      pw.SizedBox(height: 14),
      // ── Equipment info card with image ──────────────────────────────
      pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 14),
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFF0F4FF),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: PdfColor.fromInt(0xFFBFD0F7), width: 0.8),
        ),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          // Left: details
          pw.Expanded(
            flex: 3,
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text("EQUIPMENT INFORMATION",
                  style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF1E3A8A))),
              pw.Divider(color: PdfColor.fromInt(0xFFBFD0F7), height: 10, thickness: 0.5),
              _detailRow("Equipment ID",   reportEquipmentId(eqData, fallback: sosCode)),
              _detailRow("Equipment Name", _firstNonEmptyValue(eqData, ["name", "equipment_name", "type", "model"], fallback: "—")),
              _detailRow("Location",       reportLocation(eqData, fallback: 'N/A')),
              _detailRow("SOS / Asset No", sosCode),
              _detailRow("Status",         reportStatus(eqData, fallback: 'N/A')),
              pw.SizedBox(height: 8),
              pw.Text("INSPECTION DETAILS",
                  style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF1E3A8A))),
              pw.Divider(color: PdfColor.fromInt(0xFFBFD0F7), height: 10, thickness: 0.5),
              _detailRow("Inspector",       inspectorName.isNotEmpty ? inspectorName : (payload['inspector_name'] ?? 'N/A')),
              _detailRow("Inspection Date", _resolveInspectionDate(payload)),
              _detailRow("Last Inspection", reportPreviousInspection(eqData, fallback: 'N/A')),
              _detailRow("Next Due",        reportNextInspection(eqData, fallback: 'N/A')),
            ]),
          ),
          pw.SizedBox(width: 12),
          // Right: equipment image
          pw.Container(
            width: 110, height: 130,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: PdfColor.fromInt(0xFFBFD0F7), width: 0.8),
            ),
            padding: const pw.EdgeInsets.all(8),
            child: equipmentImage != null
                ? pw.Image(equipmentImage, fit: pw.BoxFit.contain)
                : pw.Center(child: pw.Text("No Image", style: const pw.TextStyle(color: PdfColors.grey400, fontSize: 8))),
          ),
        ]),
      ),
      pw.SizedBox(height: 12),

      // ── Summary stats row ────────────────────────────────────────────
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 14),
        child: pw.Row(children: [
          _statBox("TOTAL",     total.toString(),  PdfColor.fromInt(0xFFEFF6FF), PdfColor.fromInt(0xFF1D4ED8)),
          _statBox("PASS",      passed.toString(), PdfColor.fromInt(0xFFDCFCE7), PdfColor.fromInt(0xFF15803D)),
          _statBox("FAIL",      failed.toString(), PdfColor.fromInt(0xFFFEE2E2), PdfColor.fromInt(0xFFB91C1C)),
          _statBox("N/A",       naCount.toString(),PdfColor.fromInt(0xFFF1F5F9), PdfColor.fromInt(0xFF475569)),
          _statBox("COMPLETED", "$pct%",            PdfColor.fromInt(0xFFFEF3C7), PdfColor.fromInt(0xFFB45309)),
        ]),
      ),
      pw.SizedBox(height: 10),

      // ── Install status badge ─────────────────────────────────────────
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 14),
        child: pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: isCompleted ? PdfColor.fromInt(0xFFDCFCE7) : PdfColor.fromInt(0xFFFEF3C7),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(7)),
            border: pw.Border.all(
              color: isCompleted ? PdfColor.fromInt(0xFF86EFAC) : PdfColor.fromInt(0xFFFCD34D),
              width: 0.8),
          ),
          child: pw.Row(children: [
            pw.Container(
              width: 14, height: 14,
              decoration: pw.BoxDecoration(
                color: isCompleted ? PdfColor.fromInt(0xFF15803D) : PdfColor.fromInt(0xFFB45309),
                shape: pw.BoxShape.circle,
              ),
              child: pw.Center(child: pw.Text(isCompleted ? "✓" : "!", style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold))),
            ),
            pw.SizedBox(width: 8),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text("INSTALL STATUS",
                  style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold,
                      color: isCompleted ? PdfColor.fromInt(0xFF166534) : PdfColor.fromInt(0xFF92400E))),
              pw.Text(
                isCompleted
                    ? "Equipment is certified safe for operation under standard safety guidelines."
                    : "Inspection incomplete. Please complete all checklist items.",
                style: pw.TextStyle(fontSize: 7.5,
                    color: isCompleted ? PdfColor.fromInt(0xFF166534) : PdfColor.fromInt(0xFF92400E))),
            ]),
          ]),
        ),
      ),
      pw.SizedBox(height: 14),

      // ── Checklist table ──────────────────────────────────────────────
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 14),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text("CHECKLIST RESULTS",
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF0F172A))),
          pw.SizedBox(height: 6),
          _checklistTable(),
        ]),
      ),
      pw.SizedBox(height: 14),

      // ── Remarks ──────────────────────────────────────────────────────
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 14),
        child: pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF8FAFC),
            border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0), width: 0.8),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text("INSPECTION REMARKS & CORRECTIVE ACTIONS",
                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF0F172A))),
            pw.SizedBox(height: 5),
            pw.Text(
              (payload['remarks']?.toString().trim().isNotEmpty == true)
                  ? payload['remarks'].toString().trim()
                  : "No major non-conformances observed. Equipment is certified safe for operation under standard guidelines.",
              style: pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF334155), lineSpacing: 1.4),
            ),
          ]),
        ),
      ),
      pw.SizedBox(height: 18),

      // ── Signature section ────────────────────────────────────────────
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 14),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          _signatureBlock("INSPECTED BY", inspectorName.isNotEmpty ? inspectorName : (payload['inspector_name'] ?? 'N/A'), "Safety Inspector", _resolveInspectionDate(payload)),
          _signatureBlock("APPROVED BY", "Authorized Signatory", "Safety Manager / HOD", _resolveInspectionDate(payload)),
        ]),
      ),
      pw.SizedBox(height: 14),

      // ── QR placeholder ───────────────────────────────────────────────
      if (attachments.isEmpty)
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 14),
          child: _qrSection(sosCode),
        ),
    ],
  ));

  // ── PAGE 2: Attachments (MultiPage supports Expanded/layout correctly) ───────
  if (attachments.isNotEmpty) {
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      header: (_) => _header(),
      footer: (ctx) => pw.Container(
        color: PdfColor.fromInt(0xFF0D1B2A),
        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text("Report ID: $sosCode-${DateFormat('ddMMyyyy').format(DateTime.now())}",
              style: const pw.TextStyle(color: PdfColors.blueGrey100, fontSize: 7)),
          pw.Text("Page ${ctx.pageNumber} of ${ctx.pagesCount}",
              style: const pw.TextStyle(color: PdfColors.blueGrey100, fontSize: 7)),
        ]),
      ),
      build: (ctx) => [
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text("INSPECTION PHOTO ATTACHMENTS",
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF0F172A))),
            pw.SizedBox(height: 4),
            pw.Text(
              "Photos captured during field inspection as evidence of equipment condition.",
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 14),
            // Row 1
            pw.Row(children: [
              _photoCell(attachments.isNotEmpty ? attachments[0] : null, attachmentLabels[0]),
              pw.SizedBox(width: 12),
              _photoCell(attachments.length > 1 ? attachments[1] : null, attachmentLabels[1]),
            ]),
            pw.SizedBox(height: 12),
            // Row 2
            pw.Row(children: [
              _photoCell(attachments.length > 2 ? attachments[2] : null, attachmentLabels[2]),
              pw.SizedBox(width: 12),
              _photoCell(attachments.length > 3 ? attachments[3] : null, attachmentLabels[3]),
            ]),
            pw.SizedBox(height: 20),
            _qrSection(sosCode),
          ]),
        ),
      ],
    ));
  }
  return pdf;
}

pw.Widget _detailRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 75,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              color: PdfColor.fromInt(0xFF64748B), // Slate 500
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Text(": ", style: pw.TextStyle(color: PdfColor.fromInt(0xFF64748B), fontSize: 8.5)),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              color: PdfColor.fromInt(0xFF1E293B), // Slate 800
              fontSize: 8.5,
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Table cell helper ─────────────────────────────────────────────────────────
pw.Widget _tCell(String text, {bool bold = false, bool center = false, bool small = false, bool italic = false, PdfColor? color}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 5),
    child: pw.Text(
      text,
      textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
      style: pw.TextStyle(
        fontSize: small ? 7.5 : 8.5,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
        color: color ?? PdfColor.fromInt(0xFF1E293B),
      ),
    ),
  );
}

// ── Signature block helper ────────────────────────────────────────────────────
pw.Widget _signatureBlock(String role, String name, String title, String date) {
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Text(role, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF64748B))),
    pw.SizedBox(height: 30),
    pw.Container(
      width: 160,
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 1))),
    ),
    pw.SizedBox(height: 4),
    pw.Text(name, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1E293B))),
    pw.Text(title, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
    pw.SizedBox(height: 2),
    pw.Text("Date: $date", style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
  ]);
}

// ── QR placeholder section ────────────────────────────────────────────────────
pw.Widget _qrSection(String sosCode) {
  return pw.Row(children: [
    // QR box drawn with geometric shapes
    pw.Container(
      width: 48, height: 48,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromInt(0xFF1E3A8A), width: 1.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Column(children: [
          pw.Row(children: [
            pw.Container(width: 10, height: 10, color: PdfColor.fromInt(0xFF1E3A8A)),
            pw.SizedBox(width: 2),
            pw.Container(width: 5, height: 5, color: PdfColor.fromInt(0xFF1E3A8A)),
            pw.Spacer(),
            pw.Container(width: 10, height: 10, color: PdfColor.fromInt(0xFF1E3A8A)),
          ]),
          pw.SizedBox(height: 2),
          pw.Row(children: [
            pw.Container(width: 5, height: 5, color: PdfColor.fromInt(0xFF1E3A8A)),
            pw.SizedBox(width: 4),
            pw.Container(width: 8, height: 3, color: PdfColor.fromInt(0xFF1E3A8A)),
            pw.Spacer(),
            pw.Container(width: 4, height: 8, color: PdfColor.fromInt(0xFF1E3A8A)),
          ]),
          pw.Spacer(),
          pw.Row(children: [
            pw.Container(width: 10, height: 10, color: PdfColor.fromInt(0xFF1E3A8A)),
            pw.SizedBox(width: 2),
            pw.Container(width: 4, height: 4, color: PdfColor.fromInt(0xFF1E3A8A)),
          ]),
        ]),
      ),
    ),
    pw.SizedBox(width: 10),
    pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text("Scan to Verify", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1E3A8A))),
      pw.SizedBox(height: 2),
      pw.Text("Report ID: $sosCode-${DateFormat('ddMMyyyy').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
      pw.Text("This is a system-generated report.", style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
    ]),
  ]);
}

// ── Photo attachment cell ─────────────────────────────────────────────────────
pw.Widget _photoCell(pw.MemoryImage? image, String label) {
  return pw.Expanded(
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
      pw.Container(
        height: 175,
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFF8FAFC),
          border: pw.Border.all(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.8),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: image != null
            ? pw.ClipRRect(
                horizontalRadius: 6, verticalRadius: 6,
                child: pw.Image(image, fit: pw.BoxFit.cover),
              )
            : pw.Center(
                child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
                  pw.Text("NO PHOTO", style: pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFFCBD5E1), fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text("Not captured", style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey400)),
                ]),
              ),
      ),
      pw.SizedBox(height: 4),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        decoration: const pw.BoxDecoration(
          color: PdfColor.fromInt(0xFF0D1B2A),
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Text(label, textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
      ),
    ]),
  );
}



Future<pw.Document> buildPlantReportPDF({
  required String plantName,
  required String unitName,
  required DateTime startDate,
  required DateTime endDate,
  required List<Map<String, dynamic>> allData,
  pw.MemoryImage? logoImage,
  String? customTitle,
}) async {
  final pdf = pw.Document();

  // Calculate status counts
  final int totalCount = allData.length;
  final int activeCount = allData.where((e) => matchesReportStatus(e, "Active")).length;
  final int serviceCount = allData.where((e) => matchesReportStatus(e, "Needs Service")).length;
  final int inspectCount = allData.where((e) => matchesReportStatus(e, "Due Inspection")).length;
  final int expiredCount = allData.where((e) => matchesReportStatus(e, "Expired")).length;

  pdf.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        margin: const pw.EdgeInsets.all(32),
        buildForeground: (context) {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Stack(
              children: [
                pw.Positioned(
                  top: 140,
                  left: 0,
                  right: 0,
                  child: pw.Center(
                    child: pw.Transform.rotate(
                      angle: 0.4,
                      child: pw.Opacity(
                        opacity: 0.08,
                        child: pw.Text(
                          "ELTRIVE",
                          style: pw.TextStyle(
                            fontSize: 80,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                pw.Positioned(
                  top: 440,
                  left: 0,
                  right: 0,
                  child: pw.Center(
                    child: pw.Transform.rotate(
                      angle: 0.4,
                      child: pw.Opacity(
                        opacity: 0.08,
                        child: pw.Text(
                          "ELTRIVE",
                          style: pw.TextStyle(
                            fontSize: 80,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      footer: (context) {
        return pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 15),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
          ),
          padding: const pw.EdgeInsets.only(top: 5),
          child: pw.Text(
            "Page ${context.pageNumber} of ${context.pagesCount}",
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        );
      },
      build: (context) {
        final List<pw.TableRow> tableRows = [];

        // Add Header Row
        tableRows.add(
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFE2E8F0), // Slate 200
            ),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: pw.Text(
                  "SOS CODE",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColor.fromInt(0xFF1E293B)),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: pw.Text(
                  "LOCATION",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColor.fromInt(0xFF1E293B)),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: pw.Text(
                  "STATUS",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColor.fromInt(0xFF1E293B)),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: pw.Text(
                  "LAST INSPECT",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColor.fromInt(0xFF1E293B)),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: pw.Text(
                  "NEXT DUE",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColor.fromInt(0xFF1E293B)),
                ),
              ),
            ],
          ),
        );

        for (int i = 0; i < allData.length; i++) {
          final item = allData[i];
          final sosCode = reportEquipmentId(item);
          final location = reportLocation(item);
          final statusVal = reportStatus(item);
          final prevIns = reportPreviousInspection(item);
          final nextIns = reportNextInspection(item);

          final bool isEven = i % 2 == 0;
          final rowBg = isEven ? PdfColors.white : PdfColor.fromInt(0xFFF8FAFC); // Slate 50

          // Status Badge styling
          final PdfColor badgeBg;
          final PdfColor badgeBorder;
          final PdfColor badgeTextColor;
          final String badgeText;

          if (matchesReportStatus(item, "Active")) {
            badgeBg = PdfColor.fromInt(0xFFDCFCE7); // Light Green
            badgeBorder = PdfColor.fromInt(0xFF86EFAC);
            badgeTextColor = PdfColor.fromInt(0xFF15803D);
            badgeText = "ACTIVE";
          } else if (matchesReportStatus(item, "Needs Service")) {
            badgeBg = PdfColor.fromInt(0xFFFEF3C7); // Light Amber
            badgeBorder = PdfColor.fromInt(0xFFFCD34D);
            badgeTextColor = PdfColor.fromInt(0xFFB45309);
            badgeText = "SERVICE";
          } else if (matchesReportStatus(item, "Due Inspection")) {
            badgeBg = PdfColor.fromInt(0xFFDBEAFE); // Light Blue
            badgeBorder = PdfColor.fromInt(0xFF93C5FD);
            badgeTextColor = PdfColor.fromInt(0xFF1D4ED8);
            badgeText = "DUE INSPECT";
          } else if (matchesReportStatus(item, "Expired")) {
            badgeBg = PdfColor.fromInt(0xFFFEE2E2); // Light Red
            badgeBorder = PdfColor.fromInt(0xFFFCA5A5);
            badgeTextColor = PdfColor.fromInt(0xFFB91C1C);
            badgeText = "EXPIRED";
          } else {
            badgeBg = PdfColor.fromInt(0xFFF1F5F9);
            badgeBorder = PdfColor.fromInt(0xFFCBD5E1);
            badgeTextColor = PdfColor.fromInt(0xFF475569);
            badgeText = statusVal.toUpperCase();
          }

          tableRows.add(
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: rowBg,
              ),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  child: pw.Text(sosCode, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold), softWrap: false),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  child: pw.Text(location, style: const pw.TextStyle(fontSize: 8.5)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  child: pw.Container(
                    alignment: pw.Alignment.center,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: badgeBg,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        border: pw.Border.all(color: badgeBorder, width: 0.5),
                      ),
                      child: pw.Text(
                        badgeText,
                        style: pw.TextStyle(color: badgeTextColor, fontSize: 7.5, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  child: pw.Text(prevIns, style: const pw.TextStyle(fontSize: 8.5)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  child: pw.Text(nextIns, style: const pw.TextStyle(fontSize: 8.5)),
                ),
              ],
            ),
          );
        }

        final titleText = customTitle ?? "ELTRIVE PLANT REPORT";

        return [
          // 1. Header Banner
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF0F172A), // Slate 900
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      titleText.toUpperCase(),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "Eltrive Safety & Compliance System",
                      style: pw.TextStyle(
                        color: PdfColors.blueGrey100,
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
                if (logoImage != null)
                  pw.Container(
                    width: 45,
                    height: 45,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    padding: const pw.EdgeInsets.all(3),
                    child: pw.Image(logoImage),
                  ),
              ],
            ),
          ),
          pw.SizedBox(height: 15),

          // 2. Metadata Columns
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  margin: const pw.EdgeInsets.only(right: 6),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0), width: 1),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "REPORT PARAMETERS",
                        style: pw.TextStyle(
                          color: PdfColor.fromInt(0xFF1E3A8A),
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Divider(color: PdfColor.fromInt(0xFFE2E8F0), thickness: 0.5, height: 10),
                      _detailRow("Plant Category", plantName),
                      _detailRow("Facility Unit", unitName),
                      _detailRow("Date Range", "${DateFormat("dd/MM/yyyy").format(startDate)} - ${DateFormat("dd/MM/yyyy").format(endDate)}"),
                    ],
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Container(
                  margin: const pw.EdgeInsets.only(left: 6),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0), width: 1),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "EQUIPMENT STATISTICS",
                        style: pw.TextStyle(
                          color: PdfColor.fromInt(0xFF1E3A8A),
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Divider(color: PdfColor.fromInt(0xFFE2E8F0), thickness: 0.5, height: 10),
                      _detailRow("Total Inspected", "$totalCount Units"),
                      _detailRow("Active / Compliant", "$activeCount Units"),
                      _detailRow("Needs Action", "${serviceCount + inspectCount + expiredCount} Units"),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),

          // 3. Horizontal Stats Summary Bar
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF1F5F9), // Slate 100
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _statsBadge("ACTIVE", activeCount, PdfColor.fromInt(0xFF15803D)),
                _statsBadge("SERVICE", serviceCount, PdfColor.fromInt(0xFFB45309)),
                _statsBadge("DUE INSPECT", inspectCount, PdfColor.fromInt(0xFF1D4ED8)),
                _statsBadge("EXPIRED", expiredCount, PdfColor.fromInt(0xFFB91C1C)),
              ],
            ),
          ),
          pw.SizedBox(height: 15),

          // 4. Equipment Status Table Title
          pw.Text(
            "EQUIPMENT INVENTORY & COMPLIANCE STATUS",
            style: pw.TextStyle(
              color: PdfColor.fromInt(0xFF0F172A),
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),

          // 5. Table (split by row to allow automatic page breaks with a clean grid box)
          ...List.generate(tableRows.length, (index) {
            final row = tableRows[index];
            return pw.Table(
              columnWidths: const {
                0: pw.FixedColumnWidth(90), // Increased width to keep SOS code on one line
                1: pw.FlexColumnWidth(),
                2: pw.FixedColumnWidth(60),
                3: pw.FixedColumnWidth(65),
                4: pw.FixedColumnWidth(65),
              },
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              border: pw.TableBorder(
                left: const pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.8),
                right: const pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.8),
                bottom: const pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.8),
                top: index == 0 ? const pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.8) : pw.BorderSide.none,
                verticalInside: const pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 0.5),
              ),
              children: [row],
            );
          }),
          pw.SizedBox(height: 20),

          // 6. Overall Remarks Section
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF8FAFC),
              border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0), width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "PLANT AUDIT REMARKS & GENERAL STATUS",
                  style: pw.TextStyle(
                    color: PdfColor.fromInt(0xFF0F172A),
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  (expiredCount > 0)
                      ? "ALERT: $expiredCount expired items detected in the inventory. Immediate replacement or compliance inspection is required to avoid regulatory non-conformances."
                      : (serviceCount > 0)
                          ? "ATTENTION: $serviceCount items require maintenance/service. Please schedule technicians to inspect these units."
                          : "COMPLIANCE STATUS: ALL items inspected are operational and active. No immediate action required.",
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    color: PdfColor.fromInt(0xFF334155),
                    lineSpacing: 1.3,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 25),

          // 7. Signature Block
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "PREPARED BY (SAFETY OFFICER)",
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF64748B),
                    ),
                  ),
                  pw.SizedBox(height: 25),
                  pw.Container(
                    width: 150,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 1)),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    "Safety Officer",
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF1E293B),
                    ),
                  ),
                  pw.Text(
                    "Health & Safety Dept",
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey500,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "APPROVED BY (PLANT HEAD / MANAGER)",
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF64748B),
                    ),
                  ),
                  pw.SizedBox(height: 25),
                  pw.Container(
                    width: 150,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 1)),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    "Authorized Signatory",
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF1E293B),
                    ),
                  ),
                  pw.Text(
                    "Plant Management",
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ];
      },
    ),
  );

  return pdf;
}

pw.Widget _statsBadge(String label, int value, PdfColor color) {
  return pw.Row(
    children: [
      pw.Container(
        width: 8,
        height: 8,
        decoration: pw.BoxDecoration(color: color, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2))),
      ),
      pw.SizedBox(width: 4),
      pw.Text("$label: ", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
      pw.Text(value.toString(), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: color)),
    ],
  );
}
