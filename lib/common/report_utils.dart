/// Utility functions for report pages
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:fire_new/local_db.dart';

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
}) async {
  final pdf = pw.Document();
  final answers = payload['answers'] ?? [];

  // Query SQLite for the full checklist of this equipment's module
  List<Map<String, dynamic>> allChecklist = [];
  try {
    final localM = await LocalDB.findEquipmentModuleAndData(sosCode);
    final moduleCode = localM?['module_code'];
    if (moduleCode != null) {
      allChecklist = await LocalDB.getModuleRecords(
        moduleCode: moduleCode,
        recordType: 'checklist',
      );
    }
  } catch (e) {
    print("Error loading checklist: $e");
  }

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
                  "#",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColor.fromInt(0xFF1E293B)),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                child: pw.Text(
                  "CHECKLIST QUESTION / DESCRIPTION",
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
            ],
          ),
        );

        if (allChecklist.isNotEmpty) {
          // Render the complete checklist, mapping to submitted answers
          for (int i = 0; i < allChecklist.length; i++) {
            final item = allChecklist[i];
            final itemText = item["item_text"] ?? item["item"] ?? item["question"] ?? "Item ${i + 1}";
            
            // Find matching answer by comparing IDs
            Map<String, dynamic>? ans;
            final targetIdStr = item['id']?.toString().trim().toLowerCase();
            if (targetIdStr != null) {
              for (final a in answers) {
                if (a is Map && a['checklist_item_id']?.toString().trim().toLowerCase() == targetIdStr) {
                  ans = Map<String, dynamic>.from(a);
                  break;
                }
              }
            }

            final bool isEven = i % 2 == 0;
            final rowBg = isEven ? PdfColors.white : PdfColor.fromInt(0xFFF8FAFC); // Slate 50

            final itemRemarks = ans != null && ans['remarks'] != null && ans['remarks'].toString().trim().isNotEmpty
                ? ans['remarks'].toString().trim()
                : null;

            final PdfColor badgeBg;
            final PdfColor badgeBorder;
            final PdfColor badgeTextColor;
            final String badgeText;

            if (ans != null) {
              final val = ans['answer'].toString().toLowerCase();
              final isOk = val == 'true' || val == 'yes';
              final isNa = val == 'na';
              badgeBg = isOk ? PdfColor.fromInt(0xFFDCFCE7) : (isNa ? PdfColor.fromInt(0xFFF1F5F9) : PdfColor.fromInt(0xFFFEE2E2));
              badgeBorder = isOk ? PdfColor.fromInt(0xFF86EFAC) : (isNa ? PdfColor.fromInt(0xFFCBD5E1) : PdfColor.fromInt(0xFFFCA5A5));
              badgeTextColor = isOk ? PdfColor.fromInt(0xFF15803D) : (isNa ? PdfColor.fromInt(0xFF475569) : PdfColor.fromInt(0xFFB91C1C));
              badgeText = isOk ? 'YES' : (isNa ? 'N/A' : 'NO');
            } else {
              badgeBg = PdfColor.fromInt(0xFFF1F5F9);
              badgeBorder = PdfColor.fromInt(0xFFCBD5E1);
              badgeTextColor = PdfColor.fromInt(0xFF94A3B8);
              badgeText = 'NOT ANSWERED';
            }

            tableRows.add(
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: rowBg,
                ),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    child: pw.Text(
                      (i + 1).toString(), // Clean sequential index
                      style: const pw.TextStyle(fontSize: 9),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          itemText,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        if (itemRemarks != null) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            "Remarks: $itemRemarks",
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontStyle: pw.FontStyle.italic,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    child: pw.Container(
                      alignment: pw.Alignment.center,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: badgeBg,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                          border: pw.Border.all(
                            color: badgeBorder,
                            width: 0.5,
                          ),
                        ),
                        child: pw.Text(
                          badgeText,
                          style: pw.TextStyle(
                            color: badgeTextColor,
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        } else if (answers.isEmpty) {
          tableRows.add(
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(12),
                  child: pw.Text(""),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(12),
                  child: pw.Text(
                    "No offline checklist found for this equipment.",
                    style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 9, color: PdfColors.grey600),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(12),
                  child: pw.Text(""),
                ),
              ],
            ),
          );
        } else {
          // Fallback: render only the submitted answers in payload
          for (int i = 0; i < answers.length; i++) {
            final ans = answers[i];
            final val = ans['answer'].toString().toLowerCase();
            final isOk = val == 'true' || val == 'yes';
            final isNa = val == 'na';

            final bool isEven = i % 2 == 0;
            final rowBg = isEven ? PdfColors.white : PdfColor.fromInt(0xFFF8FAFC); // Slate 50

            final itemText = ans['item_text'] ?? 'Item';
            final itemRemarks = ans['remarks'] != null && ans['remarks'].toString().trim().isNotEmpty
                ? ans['remarks'].toString().trim()
                : null;

            tableRows.add(
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: rowBg,
                ),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    child: pw.Text(
                      (i + 1).toString(), // Clean sequential index
                      style: const pw.TextStyle(fontSize: 9),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          itemText,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        if (itemRemarks != null) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            "Remarks: $itemRemarks",
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontStyle: pw.FontStyle.italic,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                    child: pw.Container(
                      alignment: pw.Alignment.center,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: isOk ? PdfColor.fromInt(0xFFDCFCE7) : (isNa ? PdfColor.fromInt(0xFFF1F5F9) : PdfColor.fromInt(0xFFFEE2E2)),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                          border: pw.Border.all(
                            color: isOk ? PdfColor.fromInt(0xFF86EFAC) : (isNa ? PdfColor.fromInt(0xFFCBD5E1) : PdfColor.fromInt(0xFFFCA5A5)),
                            width: 0.5,
                          ),
                        ),
                        child: pw.Text(
                          isOk ? 'YES' : (isNa ? 'N/A' : 'NO'),
                          style: pw.TextStyle(
                            color: isOk ? PdfColor.fromInt(0xFF15803D) : (isNa ? PdfColor.fromInt(0xFF475569) : PdfColor.fromInt(0xFFB91C1C)),
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        }


        return [
          // 1. Corporate Slate-Blue Header Banner
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
                      "INSPECTION REPORT",
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      "Eltrive Safety & Compliance System",
                      style: pw.TextStyle(
                        color: PdfColors.blueGrey100,
                        fontSize: 9,
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
          pw.SizedBox(height: 20),

          // 2. Two-Column Metadata Details
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left Card: Equipment Details
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
                        "EQUIPMENT DETAILS",
                        style: pw.TextStyle(
                          color: PdfColor.fromInt(0xFF1E3A8A), // Dark Blue
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Divider(color: PdfColor.fromInt(0xFFE2E8F0), thickness: 0.5, height: 10),
                      _detailRow("Equipment ID", reportEquipmentId(eqData, fallback: sosCode)),
                      _detailRow("Location", reportLocation(eqData, fallback: 'N/A')),
                      _detailRow("SOS Number", sosCode),
                    ],
                  ),
                ),
              ),

              // Right Card: Inspector & Date Details
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
                        "INSPECTION DETAILS",
                        style: pw.TextStyle(
                          color: PdfColor.fromInt(0xFF1E3A8A),
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Divider(color: PdfColor.fromInt(0xFFE2E8F0), thickness: 0.5, height: 10),
                      _detailRow("Inspector Name", inspectorName.isNotEmpty ? inspectorName : (payload['inspector_name'] ?? 'N/A')),
                      _detailRow("Inspection Date", _resolveInspectionDate(payload)),
                      _detailRow("Status", answers.isNotEmpty ? "Completed" : "Pending"),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 25),

          // 3. Checklist Section Title
          pw.Text(
            "CHECKLIST RESULTS",
            style: pw.TextStyle(
              color: PdfColor.fromInt(0xFF0F172A),
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),

          // 4. Checklist Results Table (split by row to allow automatic page breaks with a clean grid box)
          ...List.generate(tableRows.length, (index) {
            final row = tableRows[index];
            return pw.Table(
              columnWidths: const {
                0: pw.FixedColumnWidth(25),
                1: pw.FlexColumnWidth(),
                2: pw.FixedColumnWidth(60),
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

          // 5. Overall Remarks Section
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF8FAFC), // Slate 50
              border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0), width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "INSPECTION REMARKS & CORRECTIVE ACTIONS",
                  style: pw.TextStyle(
                    color: PdfColor.fromInt(0xFF0F172A),
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  (payload['remarks'] != null && payload['remarks'].toString().trim().isNotEmpty)
                      ? payload['remarks'].toString().trim()
                      : "No major non-conformances observed. Equipment is certified safe for operation under standard guidelines.",
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    color: PdfColor.fromInt(0xFF334155), // Slate 700
                    lineSpacing: 1.3,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 25),

          // 6. Sign-off / Signature Section
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Inspector Column
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "INSPECTED BY",
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF64748B), // Slate 500
                    ),
                  ),
                  pw.SizedBox(height: 25), // Signature space
                  pw.Container(
                    width: 150,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1), width: 1)),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    inspectorName.isNotEmpty ? inspectorName : (payload['inspector_name'] ?? 'N/A'),
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF1E293B), // Slate 800
                    ),
                  ),
                  pw.Text(
                    "Safety Inspector",
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey500,
                    ),
                  ),
                ],
              ),

              // Approver Column
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "APPROVED BY",
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF64748B),
                    ),
                  ),
                  pw.SizedBox(height: 25), // Signature space
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
                    "Safety Manager / HOD",
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
