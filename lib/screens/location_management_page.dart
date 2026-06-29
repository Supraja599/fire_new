import 'package:flutter/material.dart';
import 'package:fire_new/services/apiservice.dart';
import 'package:hive/hive.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationManagementPage extends StatefulWidget {
  final bool isDark;
  const LocationManagementPage({super.key, required this.isDark});

  @override
  State<LocationManagementPage> createState() => _LocationManagementPageState();
}

class _LocationManagementPageState extends State<LocationManagementPage> {
  List<Map<String, dynamic>> _locations = [];
  String? _companyId;
  bool _loading = true;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController();
  final _sosCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _radiusCtrl.dispose();
    _sosCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final box = Hive.box('inspectionBox');
      final companyId = box.get('companyId', defaultValue: '28').toString();
      final locations = await ApiService.getLocations(companyId: companyId);

      setState(() {
        _companyId = companyId;
        _locations = locations;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _showAssignSheet(Map<String, dynamic> loc) {
    final locationId = (loc['id'] ?? loc['location_id'])?.toString() ?? '';
    final locationName = loc['location_name']?.toString() ?? 'Location';

    // Controllers for SOS ID rows
    final rows = <TextEditingController>[TextEditingController()];
    bool assigning = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 16,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle + close
                Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 40, height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(sheetCtx),
                      color: widget.isDark ? Colors.white70 : Colors.black54,
                    ),
                  ],
                ),
                // Location title
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Color(0xFFD50000), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        locationName,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: widget.isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Assign equipment SOS IDs to this location",
                  style: TextStyle(fontSize: 12, color: widget.isDark ? Colors.white54 : Colors.grey.shade600),
                ),
                const Divider(height: 24),

                // SOS ID rows
                ...rows.asMap().entries.map((entry) {
                  final i = entry.key;
                  final ctrl = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ctrl,
                            textCapitalization: TextCapitalization.characters,
                            style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              labelText: "SOS ID ${rows.length > 1 ? '#${i + 1}' : ''}",
                              prefixIcon: const Icon(Icons.qr_code_rounded, color: Color(0xFFD50000)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                          ),
                        ),
                        if (rows.length > 1)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => setSheet(() => rows.removeAt(i)),
                          ),
                      ],
                    ),
                  );
                }),

                // Add another row
                TextButton.icon(
                  onPressed: () => setSheet(() => rows.add(TextEditingController())),
                  icon: const Icon(Icons.add_rounded, color: Color(0xFFD50000)),
                  label: const Text("Add another SOS ID", style: TextStyle(color: Color(0xFFD50000))),
                ),
                const SizedBox(height: 12),

                // Assign button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD50000),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: assigning
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.link_rounded, color: Colors.white),
                    label: Text(
                      assigning ? "Assigning..." : "ASSIGN TO LOCATION",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: assigning
                        ? null
                        : () async {
                            final sosCodes = rows
                                .map((c) => c.text.trim().toUpperCase())
                                .where((s) => s.isNotEmpty)
                                .toList();
                            final messenger = ScaffoldMessenger.of(context);

                            if (sosCodes.isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text("Enter at least one SOS ID")),
                              );
                              return;
                            }

                            setSheet(() => assigning = true);

                            final assignments = sosCodes
                                .map((s) => {"sos_code": s, "location_id": locationId})
                                .toList();

                            final result = await ApiService.bulkAssignEquipmentLocations(assignments);

                            setSheet(() => assigning = false);

                            if (!mounted) return;

                            final success = result['success'] == true ||
                                result['assigned'] != null ||
                                result['message']?.toString().toLowerCase().contains('success') == true;

                            Navigator.pop(sheetCtx);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? "${sosCodes.length} equipment assigned to $locationName"
                                      : result['message']?.toString() ?? "Assignment failed",
                                ),
                                backgroundColor: success ? Colors.green : Colors.red,
                              ),
                            );
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(bool autoGeocode) async {
    if (!_formKey.currentState!.validate()) return;
    if (_companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Company ID not resolved. Please try again."), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _submitting = true);

    final latText = _latCtrl.text.trim();
    final lngText = _lngCtrl.text.trim();

    final ok = await ApiService.createLocation(
      companyId: _companyId!,
      locationName: _nameCtrl.text.trim(),
      latitude: latText.isNotEmpty ? double.tryParse(latText) : null,
      longitude: lngText.isNotEmpty ? double.tryParse(lngText) : null,
      geofenceRadiusMeters: double.parse(_radiusCtrl.text.trim()),
      autoGeocode: autoGeocode,
      sosCode: _sosCtrl.text.trim().isNotEmpty ? _sosCtrl.text.trim() : null,
    );

    setState(() => _submitting = false);

    if (!mounted) return;

    if (ok) {
      _nameCtrl.clear();
      _latCtrl.clear();
      _lngCtrl.clear();
      _radiusCtrl.clear();
      _sosCtrl.clear();
      Navigator.pop(context); // close sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Location added successfully"),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to add location. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddSheet() {
    bool localAutoGeocode = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sheet handle + title row
                  Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetCtx),
                        color: widget.isDark ? Colors.white70 : Colors.black54,
                      ),
                    ],
                  ),
                  Text(
                    "Add New Location",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location Name
                  TextFormField(
                    controller: _nameCtrl,
                    style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: "Location Name (Address)",
                      prefixIcon: const Icon(Icons.label_rounded, color: Color(0xFFD50000)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? "Location name is required" : null,
                  ),
                  const SizedBox(height: 12),

                  // SOS Code (Optional)
                  TextFormField(
                    controller: _sosCtrl,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: "SOS Code / Equipment ID (Optional)",
                      prefixIcon: const Icon(Icons.qr_code_rounded, color: Color(0xFFD50000)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Switch for Auto Geocode
                  SwitchListTile(
                    title: Text(
                      "Auto Geocode Address",
                      style: TextStyle(
                        color: widget.isDark ? Colors.white : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      "Let the server resolve coordinates from address",
                      style: TextStyle(
                        color: widget.isDark ? Colors.white54 : Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                    value: localAutoGeocode,
                    activeColor: const Color(0xFFD50000),
                    onChanged: (val) {
                      setSheetState(() {
                        localAutoGeocode = val;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Latitude + Longitude side by side
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            labelText: "Latitude" + (localAutoGeocode ? " (Optional)" : ""),
                            prefixIcon: const Icon(Icons.my_location_rounded, color: Color(0xFFD50000)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) {
                            if (localAutoGeocode) return null;
                            if (v == null || v.trim().isEmpty) return "Required";
                            if (double.tryParse(v.trim()) == null) return "Invalid";
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _lngCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: true),
                          style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            labelText: "Longitude" + (localAutoGeocode ? " (Optional)" : ""),
                            prefixIcon: const Icon(Icons.explore_rounded, color: Color(0xFFD50000)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) {
                            if (localAutoGeocode) return null;
                            if (v == null || v.trim().isEmpty) return "Required";
                            if (double.tryParse(v.trim()) == null) return "Invalid";
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Get current coordinates button
                  TextButton.icon(
                    onPressed: () async {
                      try {
                        final pos = await Geolocator.getCurrentPosition(
                          desiredAccuracy: LocationAccuracy.high,
                          timeLimit: const Duration(seconds: 8),
                        );
                        _latCtrl.text = pos.latitude.toString();
                        _lngCtrl.text = pos.longitude.toString();
                        setSheetState(() {
                          localAutoGeocode = false; // Turn off auto-geocode since we fetched directly
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(sheetCtx).showSnackBar(
                          SnackBar(content: Text("Failed to get location: $e"), backgroundColor: Colors.red),
                        );
                      }
                    },
                    icon: const Icon(Icons.gps_fixed_rounded, color: Color(0xFFD50000)),
                    label: const Text(
                      "Fill Current GPS Coordinates",
                      style: TextStyle(color: Color(0xFFD50000), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Geofence Radius
                  TextFormField(
                    controller: _radiusCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: "Geofence Radius (meters)",
                      prefixIcon: const Icon(Icons.radar_rounded, color: Color(0xFFD50000)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Required";
                      final n = double.tryParse(v.trim());
                      if (n == null || n <= 0) return "Enter a valid positive number";
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD50000),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.add_location_alt_rounded,
                              color: Colors.white),
                      label: Text(
                        _submitting ? "Saving..." : "ADD LOCATION",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      onPressed: _submitting ? null : () => _submit(localAutoGeocode),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F6FA);
    final cardBg = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final subColor = widget.isDark ? Colors.white60 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          "Location Management",
          style: TextStyle(
              fontWeight: FontWeight.bold, color: textColor, fontSize: 18),
        ),
        iconTheme: IconThemeData(color: textColor),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: "Refresh",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: const Color(0xFFD50000),
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: const Text("Add Location",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD50000)))
          : Column(
              children: [
                Expanded(
                  child: _locations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_off_rounded,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                "No locations added yet",
                                style: TextStyle(
                                    color: subColor, fontSize: 15),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap "Add Location" to get started',
                                style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: _locations.length,
                          itemBuilder: (context, index) {
                            final loc = _locations[index];
                            final name =
                                loc['location_name']?.toString() ?? 'Unknown';
                            final lat = loc['latitude']?.toString() ?? '—';
                            final lng = loc['longitude']?.toString() ?? '—';
                            final radius =
                                loc['geofence_radius_meters']?.toString() ??
                                    '—';
                            final assignedEq = loc['assigned_equipment_id']?.toString() ?? loc['sos_code']?.toString() ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: widget.isDark ? 0.3 : 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  onTap: () => _showAssignSheet(loc),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD50000).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.location_on_rounded,
                                        color: Color(0xFFD50000)),
                                  ),
                                  title: Text(
                                    name,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textColor),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Lat: $lat  •  Lng: $lng",
                                          style: TextStyle(color: subColor, fontSize: 12),
                                        ),
                                        Text(
                                          "Radius: ${radius}m",
                                          style: TextStyle(color: subColor, fontSize: 12),
                                        ),
                                        if (assignedEq.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.qr_code_2_rounded, size: 14, color: Color(0xFFD50000)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "Assigned Equipment: $assignedEq",
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 12,
                                                      color: Color(0xFFD50000)),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  isThreeLine: true,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (lat != '—' && lng != '—')
                                        IconButton(
                                          icon: const Icon(Icons.map_rounded, color: Color(0xFFD50000)),
                                          tooltip: "Open Map",
                                          onPressed: () async {
                                            final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
                                            if (await canLaunchUrl(url)) {
                                              await launchUrl(url, mode: LaunchMode.externalApplication);
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Could not open maps application")),
                                              );
                                            }
                                          },
                                        ),
                                      () {
                                        final locId = (loc['id'] ?? loc['location_id'])?.toString();
                                        if (locId == null) return const SizedBox();
                                        return IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                title: const Text("Delete Location"),
                                                content: Text('Remove "$name"?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(ctx, false),
                                                    child: const Text("Cancel"),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                    onPressed: () => Navigator.pop(ctx, true),
                                                    child: const Text("Delete", style: TextStyle(color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              final ok = await ApiService.deleteLocation(locId);
                                              if (ok) {
                                                _loadData();
                                              } else if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text("Failed to delete location"), backgroundColor: Colors.red),
                                                );
                                              }
                                            }
                                          },
                                        );
                                      }(),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
