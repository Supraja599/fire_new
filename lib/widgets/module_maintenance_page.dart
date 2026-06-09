import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/utils/map_flatten.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ModuleMaintenancePage extends StatefulWidget {
  final String title;
  final String imagePath;
  final ModuleApiService api;

  const ModuleMaintenancePage({
    super.key,
    required this.title,
    required this.imagePath,
    required this.api,
  });

  @override
  State<ModuleMaintenancePage> createState() => _ModuleMaintenancePageState();
}

class _ModuleMaintenancePageState extends State<ModuleMaintenancePage> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime? _parseDate(String? val) {
    if (val == null || val.isEmpty) return null;
    try {
      return DateTime.parse(val).toLocal();
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    try {
      final equipment = await widget.api.getEquipmentList();
      final rows = <Map<String, dynamic>>[];
      for (final item in equipment) {
        final status = item["status_bucket"]?.toString().toLowerCase() ?? "active";
        if (status == "expired") continue;
        final date = _parseDate(item["next_inspection_due"]?.toString());
        rows.add({
          "sos_id": (item["sos_code"] ?? item["serial_number"] ?? item["id"] ?? "N/A").toString(),
          "location": (item["location_name"] ?? item["zone_name"] ?? item["building_name"] ?? "-").toString(),
          "due_date": date,
          "type": (item["extinguisher_type"] ?? item["type"] ?? item["equipment_type"] ??
              item["category"] ?? item["brand"] ?? "-").toString(),
          "status": status,
          "raw": item,
        });
      }
      rows.sort((a, b) {
        final aDate = a["due_date"] as DateTime?;
        final bDate = b["due_date"] as DateTime?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'needs-service':
        return const Color(0xFFEF6C00);
      case 'due-inspection':
        return const Color(0xFF1565C0);
      default:
        return Colors.green;
    }
  }

  void _showDetails(Map<String, dynamic> row) {
    final raw = row["raw"] as Map<String, dynamic>;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Pinned header — always visible
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 4, 0),
              child: Row(
                children: [
                  Center(
                    child: Container(
                      width: 48, height: 5,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
            ),
            Text(
              row["sos_id"].toString(),
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF6C00)),
            ),
            const Divider(height: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: buildDetailRows(raw),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.title,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _rows = [];
                  _loading = true;
                });
                await _load();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Module image header
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFF3E0), Color(0xFFFFF8F0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 28, horizontal: 16),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              widget.imagePath,
                              height: 80,
                              width: 80,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.build,
                                  size: 60,
                                  color: Colors.orange),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFBF360C),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Upcoming heading + count badge
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule_rounded,
                              color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text(
                            "Upcoming Maintenance",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${_rows.length} items",
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Table or empty state
                    if (_rows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 60, color: Colors.green.shade300),
                            const SizedBox(height: 12),
                            Text(
                              "All equipment is up to date",
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          clipBehavior: Clip.antiAlias,
                          child: Table(
                            columnWidths: const {
                              0: FlexColumnWidth(3.0),
                              1: FlexColumnWidth(2.2),
                              2: FlexColumnWidth(2.2),
                              3: FlexColumnWidth(1.6),
                            },
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            children: [
                              // Header row
                              TableRow(
                                decoration: BoxDecoration(
                                    color: Colors.orange.shade50),
                                children: const [
                                  _TableHeader("SOS ID"),
                                  _TableHeader("Location"),
                                  _TableHeader("Next Due"),
                                  _TableHeader("Type"),
                                ],
                              ),
                              // Data rows
                              ..._rows.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final row = entry.value;
                                final date = row["due_date"] as DateTime?;
                                final dateStr = date != null
                                    ? DateFormat('dd MMM yy').format(date)
                                    : "-";
                                final status = row["status"] as String;
                                final statusColor = _statusColor(status);
                                final bg = idx.isOdd
                                    ? Colors.grey.shade50
                                    : Colors.white;
                                return TableRow(
                                  decoration: BoxDecoration(color: bg),
                                  children: [
                                    _TableTapCell(
                                      onTap: () => _showDetails(row),
                                      child: Text(
                                        row["sos_id"].toString(),
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ),
                                    _TableTapCell(
                                      onTap: () => _showDetails(row),
                                      child: Text(
                                        row["location"].toString(),
                                        style: const TextStyle(fontSize: 11),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    _TableTapCell(
                                      onTap: () => _showDetails(row),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(
                                              alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          dateStr,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                    _TableTapCell(
                                      onTap: () => _showDetails(row),
                                      child: Text(
                                        row["type"].toString(),
                                        style: const TextStyle(fontSize: 11),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _TableTapCell extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TableTapCell({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: child,
      ),
    );
  }
}
