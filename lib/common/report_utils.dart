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
        buildBackground: (context) {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Center(
              child: pw.Transform.rotate(
                angle: 0.6,
                child: pw.Opacity(
                  opacity: 0.05,
                  child: pw.Text(
                    "ELTRIVE",
                    style: pw.TextStyle(
                      fontSize: 120,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey,
                    ),
                  ),
                ),
              ),
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
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(4),
                topRight: pw.Radius.circular(4),
              ),
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
                  border: const pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  ),
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
                  border: const pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  ),
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
                      _detailRow("Inspection Date", DateFormat("dd-MM-yyyy").format(DateTime.now())),
                      _detailRow(
                        "Remarks",
                        (payload['remarks'] != null && payload['remarks'].toString().trim().isNotEmpty)
                            ? payload['remarks'].toString().trim()
                            : "None",
                      ),
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

          // 4. Checklist Results Table
          pw.Table(
            columnWidths: const {
              0: pw.FixedColumnWidth(25),
              1: pw.FlexColumnWidth(),
              2: pw.FixedColumnWidth(60),
            },
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: tableRows,
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
