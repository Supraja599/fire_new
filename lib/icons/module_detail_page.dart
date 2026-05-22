import 'package:flutter/material.dart';
import 'package:fire_new/alarm_panel/services/alarm_panel_api_service.dart';
import 'package:fire_new/hosereel/services/apiservice.dart';
import 'package:fire_new/hydrant/services/hydrant_api_service.dart';
import 'package:fire_new/splinkers/services/sprinkler_api_service.dart';
import 'package:fire_new/smoke_detector/services/smoke_detector_api_service.dart';
import 'package:fire_new/fire_trolley/services/fire_trolley_api_service.dart';

class ModuleDetailPage extends StatefulWidget {
  final String title;
  final dynamic apiService; // expects methods: getSummary(), getEquipmentByQuery(String)

  const ModuleDetailPage({required this.title, required this.apiService, super.key});

  @override
  State<ModuleDetailPage> createState() => _ModuleDetailPageState();
}

class _ModuleDetailPageState extends State<ModuleDetailPage> {
  bool isLoading = true;
  Map<String, dynamic>? summary;
  String query = '';
  Map<String, dynamic>? equipmentDetail;
  String statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final data = await widget.apiService.getSummary();
      if (mounted) {
        setState(() {
          summary = data as Map<String, dynamic>;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          statusMessage = 'Failed to load summary: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchEquipment() async {
    if (query.trim().isEmpty) return;
    setState(() => statusMessage = 'Loading equipment...');
    try {
      final data = await widget.apiService.getEquipmentByQuery(query.trim());
      if (mounted) {
        setState(() {
          equipmentDetail = data as Map<String, dynamic>?;
          statusMessage = equipmentDetail != null ? 'Equipment found' : 'No equipment found';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => statusMessage = 'Error fetching equipment: $e');
      }
    }
  }

  Widget _buildSummary() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (summary == null) return const Text('No summary data');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total: ${summary!["total"] ?? summary!["total_units"] ?? "-"}'),
        Text('Active: ${((summary!["active"] ?? summary!["active_units"] ?? 0) as int) + ((summary!["upcoming"] ?? summary!["upcoming_units"] ?? 0) as int)}'),
        Text('Needs Service: ${summary!["needs_service"] ?? "-"}'),
        Text('Due Inspection: ${summary!["due_inspection"] ?? "-"}'),
        Text('Expired: ${summary!["expired"] ?? "-"}'),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(labelText: 'Enter equipment ID or SOS code'),
          onChanged: (v) => query = v,
          onSubmitted: (_) => _fetchEquipment(),
        ),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _fetchEquipment, child: const Text('Fetch Details')),
        const SizedBox(height: 8),
        Text(statusMessage),
        if (equipmentDetail != null) _buildEquipmentDetail(),
      ],
    );
  }

  Widget _buildEquipmentDetail() {
    // ✅ FLATTEN NESTED DATA FOR TABLE DISPLAY
    final Map<String, String> displayFields = {};
    void flatten(Map<dynamic, dynamic> map, [String prefix = ""]) {
      map.forEach((key, value) {
        final displayKey = prefix.isEmpty ? key.toString() : "${prefix}_$key";
        if (value is Map) {
          flatten(value, displayKey);
        } else if (value != null && value is! List) {
          displayFields[displayKey] = value.toString();
        }
      });
    }

    flatten(equipmentDetail!);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "EQUIPMENT DETAILS",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
            ),
            const Divider(),
            Table(
              columnWidths: const {0: FlexColumnWidth(4), 1: FlexColumnWidth(6)},
              border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade200)),
              children: displayFields.entries.map((e) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        e.key.replaceAll("_", " ").toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(e.value, style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(child: _buildSummary()),
      ),
    );
  }
}
