import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:hive/hive.dart';
import '../services/location_service.dart';
import '../services/equipment_repository.dart';
import '../services/service_locator.dart';
import '../guided_capture_wizard.dart';

/// Unified checklist widget used by all 26 modules.
/// fromScan = true  → came from QR/barcode scan, equipment ID auto-filled, no image wizard.
/// fromScan = false → opened directly from dashboard, equipment ID is blank (user enters manually).
class GenericChecklistPage extends StatefulWidget {
  final String? equipmentId;
  final Map<String, dynamic>? selectedEquipment;
  final bool fromScan;
  final String moduleCode;
  final String moduleName;
  final Color primaryColor;
  final String eventIdPrefix;
  final Future<List<Map<String, dynamic>>> Function() fetchChecklist;

  const GenericChecklistPage({
    super.key,
    this.equipmentId,
    this.selectedEquipment,
    this.fromScan = true,
    required this.moduleCode,
    required this.moduleName,
    required this.primaryColor,
    required this.eventIdPrefix,
    required this.fetchChecklist,
  });

  @override
  State<GenericChecklistPage> createState() => _GenericChecklistPageState();
}

class _GenericChecklistPageState extends State<GenericChecklistPage> {
  final TextEditingController _equipCtrl   = TextEditingController();
  final TextEditingController _inspCtrl    = TextEditingController();
  final TextEditingController _remarksCtrl = TextEditingController();

  final Map<int, String> _answers = {};
  List<Map<String, dynamic>> _checklist = [];
  bool _loading = true;
  bool _saving  = false;
  List<String>? _capturedImages;

  @override
  void initState() {
    super.initState();
    // Retrieve and immediately clear Wizard images from cache
    _capturedImages = GuidedCaptureWizardPage.latestCapturedImagesBase64;
    GuidedCaptureWizardPage.latestCapturedImagesBase64 = null;

    // Auto-populate equipment ID: prefer selectedEquipment (from scan), else equipmentId param
    if (widget.selectedEquipment != null) {
      _equipCtrl.text =
          widget.selectedEquipment!["sos_code"]?.toString()      ??
          widget.selectedEquipment!["equipment_id"]?.toString()  ??
          widget.selectedEquipment!["id"]?.toString()            ?? "";
    } else if (widget.equipmentId != null) {
      _equipCtrl.text = widget.equipmentId!;
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await widget.fetchChecklist();
      if (!mounted) return;
      setState(() {
        _checklist = items.isNotEmpty ? items : _fallback();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _checklist = _fallback(); _loading = false; });
    }
  }

  List<Map<String, dynamic>> _fallback() => [
    {"id": 1, "item_text": "${widget.moduleName} is accessible and clearly visible"},
    {"id": 2, "item_text": "${widget.moduleName} shows no visible damage or defects"},
    {"id": 3, "item_text": "Labels and instructions are legible"},
    {"id": 4, "item_text": "Safety seals and tags are intact"},
    {"id": 5, "item_text": "Last inspection date is within acceptable range"},
  ];

  @override
  void dispose() {
    _equipCtrl.dispose();
    _inspCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // --- GEOLOCATION PROXIMITY CHECK ---
    final eq = widget.selectedEquipment;
    if (eq != null) {
      final lat = double.tryParse((eq["latitude"] ?? eq["lat"] ?? "").toString());
      final lng = double.tryParse((eq["longitude"] ?? eq["lng"] ?? "").toString());
      if (lat != null && lng != null) {
        if (mounted) showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AlertDialog(
            content: Row(children: [
              CircularProgressIndicator(color: Colors.red),
              SizedBox(width: 20),
              Text("Verifying physical presence..."),
            ]),
          ),
        );
        final result = await LocationService.verifyProximity(
          targetLat: lat, targetLng: lng, maxAllowedDistanceMeters: 100.0,
        );
        if (mounted) Navigator.pop(context);
        if (!result.success || !result.withinRange) {
          if (mounted) showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Row(children: [
                Icon(Icons.error_outline_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text("Location Required", style: TextStyle(color: Colors.red)),
              ]),
              content: Text(
                result.withinRange
                    ? (result.errorMessage ?? "Location error")
                    : "You are ${result.distanceMeters?.toStringAsFixed(1) ?? '?'} m away.\nMust be within 100 m of the equipment.",
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
            ),
          );
          return;
        }
      }
    }

    // --- VALIDATION ---
    final id        = _equipCtrl.text.trim();
    final inspector = _inspCtrl.text.trim();
    if (id.isEmpty || inspector.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter Equipment ID and Inspector Name")),
      );
      return;
    }

    // Check if there are any unanswered questions
    final missingIndices = <int>[];
    for (int i = 0; i < _checklist.length; i++) {
      if (!_answers.containsKey(i) || _answers[i] == null) {
        missingIndices.add(i);
      }
    }

    if (missingIndices.isNotEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: Icon(Icons.warning_amber_rounded, size: 50, color: Colors.orange.shade800),
            title: const Text(
              "Checklist Incomplete",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Please answer all checklist items before submitting. You have answered ${_answers.length} out of ${_checklist.length} questions.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4, fontSize: 15),
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Build the answers list and find the anomalies (items marked NO)
    final anomalies = <String>[];
    final payloadAnswers = <Map<String, dynamic>>[];
    for (var i = 0; i < _checklist.length; i++) {
      final answer = _answers[i];
      final itemId = _checklist[i]["id"];
      if (answer == null || itemId == null) continue;
      final text = _checklist[i]["item_text"] ?? _checklist[i]["item"] ??
                   _checklist[i]["question"] ?? "Item ${i + 1}";
      payloadAnswers.add({
        "checklist_item_id": itemId,
        "item_text": text,
        "answer": answer == "YES" ? "true" : answer == "NO" ? "false" : "na",
        "remarks": "",
      });

      if (answer == "NO") {
        anomalies.add(text);
      }
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final Color primaryColor = widget.primaryColor;
        final bool hasAnomalies = anomalies.isNotEmpty;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Icon(
            hasAnomalies ? Icons.report_problem_rounded : Icons.check_circle_rounded,
            size: 50,
            color: hasAnomalies ? Colors.red.shade700 : Colors.green.shade700,
          ),
          title: Text(
            hasAnomalies ? "Anomalies Flagged" : "Confirm Submission",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasAnomalies) ...[
                  Text(
                    "You flagged the following items as failing/incorrect:",
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: anomalies.length,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.circle, size: 8, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    anomalies[index],
                                    style: TextStyle(
                                      color: Colors.red.shade900,
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                ] else ...[
                  Text(
                    "All checklist items are marked as passed or not applicable.",
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                ],
                Text(
                  "Are you sure you want to submit this checklist?",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade900, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasAnomalies ? Colors.red.shade700 : primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      "Submit",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _saving = true);

    try {
      final box = Hive.isBoxOpen('inspectionBox') ? Hive.box<dynamic>('inspectionBox') : null;
      if (box != null) {
        await box.put('last_equipment_id_${widget.moduleCode}', id);
        await box.put('last_inspector_name_${widget.moduleCode}', inspector);
        await box.put('last_equipment_id', id);
        await box.put('last_inspector_name', inspector);
      }
    } catch (_) {}

    await locator<EquipmentRepository>().submitInspection(
      eventId: "${widget.eventIdPrefix}-${DateTime.now().millisecondsSinceEpoch}",
      moduleCode: widget.moduleCode,
      equipmentId: id,
      inspectorName: inspector,
      remarks: _remarksCtrl.text.trim(),
      answers: payloadAnswers,
      images: _capturedImages ?? [],
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E8E3E),
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text("${widget.moduleName} inspection saved! Check Reports.")),
        ]),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.primaryColor;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: c, title: Text("${widget.moduleName} Checklist", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), iconTheme: const IconThemeData(color: Colors.white)),
        body: Center(child: CircularProgressIndicator(color: c)),
      );
    }

    final idReadOnly = widget.fromScan && _equipCtrl.text.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: c,
        elevation: 0,
        title: Text("${widget.moduleName} Checklist",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _answers.length / (_checklist.isEmpty ? 1 : _checklist.length),
            backgroundColor: c.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Equipment Info Card ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(children: [
                _field(_equipCtrl, "Equipment ID / SOS Code",
                    Icons.qr_code_scanner_rounded, c, readOnly: idReadOnly),
                const SizedBox(height: 12),
                _field(_inspCtrl, "Inspector Name", Icons.badge_rounded, c),
              ]),
            ),
            const SizedBox(height: 14),

            // ── Progress Chip & Bulk Selection ───────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    "${_answers.length} / ${_checklist.length} answered",
                    style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _bulkActionButton("ALL YES", const Color(0xFF1E8E3E), () {
                      setState(() {
                        for (int i = 0; i < _checklist.length; i++) {
                          _answers[i] = "YES";
                        }
                      });
                    }),
                    const SizedBox(width: 8),
                    _bulkActionButton("ALL NO", const Color(0xFFD50000), () {
                      setState(() {
                        for (int i = 0; i < _checklist.length; i++) {
                          _answers[i] = "NO";
                        }
                      });
                    }),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Checklist Items ──────────────────────────────────
            ...List.generate(_checklist.length, (i) {
              final item   = _checklist[i];
              final answer = _answers[i];
              final text   = item["item_text"] ?? item["item"] ??
                             item["question"]  ?? item["question_text"] ??
                             item["name"]      ?? item["title"] ?? "Item ${i + 1}";

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: answer == null
                        ? Colors.grey.withValues(alpha: 0.15)
                        : (answer == "YES"
                            ? const Color(0xFF1E8E3E).withValues(alpha: 0.4)
                            : answer == "NO"
                                ? const Color(0xFFD50000).withValues(alpha: 0.4)
                                : const Color(0xFFFF8F00).withValues(alpha: 0.4)),
                    width: 1.5,
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: Text("${i + 1}", style: TextStyle(color: c, fontWeight: FontWeight.w900, fontSize: 12))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, height: 1.3))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    _choice(i, "YES", answer == "YES", const Color(0xFF1E8E3E)),
                    const SizedBox(width: 8),
                    _choice(i, "NO",  answer == "NO",  const Color(0xFFD50000)),
                    const SizedBox(width: 8),
                    _choice(i, "NA",  answer == "NA",  const Color(0xFFFF8F00)),
                  ]),
                ]),
              );
            }),

            const SizedBox(height: 8),

            if (_capturedImages != null && _capturedImages!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.photo_library_rounded, color: c, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Captured Inspection Photos",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _capturedImages!.length,
                        itemBuilder: (context, idx) {
                          return Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200, width: 1.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                base64Decode(_capturedImages![idx]),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.broken_image, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ── Remarks ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
              ),
              child: TextField(
                controller: _remarksCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Remarks (Optional)",
                  labelStyle: TextStyle(color: c),
                  prefixIcon: Icon(Icons.notes_rounded, color: c),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: c, width: 2),
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Submit ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: c,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                ),
                icon: _saving
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                label: Text(
                  _saving ? "Saving..." : "SUBMIT INSPECTION",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900,
                      fontSize: 15, letterSpacing: 0.4),
                ),
                onPressed: _saving ? null : _submit,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, Color color,
      {bool readOnly = false}) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color),
        prefixIcon: Icon(icon, color: color),
        suffixIcon: readOnly ? const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: color, width: 2),
            borderRadius: BorderRadius.circular(10)),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey.shade100 : null,
      ),
    );
  }

  Widget _choice(int index, String label, bool selected, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _answers[index] = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? color : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selected ? color : Colors.grey.shade200, width: 1.5),
            boxShadow: selected
                ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                )),
          ),
        ),
      ),
    );
  }

  Widget _bulkActionButton(String label, Color color, VoidCallback onTap) {
    final isYes = label == "ALL YES";
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isYes ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
              size: 13,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
