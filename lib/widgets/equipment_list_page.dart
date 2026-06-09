import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fire_new/utils/upper_case_text_formatter.dart';
import 'package:fire_new/utils/map_flatten.dart';

class EquipmentListPage extends StatefulWidget {
  final String title;
  final Color color;
  final List<Map<String, dynamic>> items;
  final String imagePath;
  final IconData fallbackIcon;

  const EquipmentListPage({
    super.key,
    required this.title,
    required this.color,
    required this.items,
    required this.imagePath,
    required this.fallbackIcon,
  });

  @override
  State<EquipmentListPage> createState() => _EquipmentListPageState();
}

class _EquipmentListPageState extends State<EquipmentListPage> {
  late List<Map<String, dynamic>> filteredItems;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredItems = widget.items;
  }

  void _filter(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredItems = widget.items;
      } else {
        filteredItems = widget.items.where((item) {
          final sosId = (item["sos_code"] ?? item["serial_number"] ?? item["id"] ?? "").toString().toLowerCase();
          final loc = (item["location_name"] ?? item["building_name"] ?? "").toString().toLowerCase();
          final zone = (item["zone_name"] ?? "").toString().toLowerCase();
          return sosId.contains(query.toLowerCase()) || 
                 loc.contains(query.toLowerCase()) || 
                 zone.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: TextField(
              controller: searchController,
              onChanged: _filter,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                UpperCaseTextFormatter(),
              ],
              decoration: InputDecoration(
                hintText: "Search by SOS ID, Location or Zone...",
                prefixIcon: Icon(Icons.search, color: widget.color),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(child: Text("No items found"))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final sosId = item["sos_code"] ?? item["serial_number"] ?? item["id"] ?? "-";
                      final location = item["location_name"] ?? item["building_name"] ?? "Unknown";

                      return GestureDetector(
                        onTap: () => _showDetails(context, item),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: widget.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    widget.imagePath,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => Icon(widget.fallbackIcon, color: widget.color),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "SOS ID: $sosId",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black87,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            location.toString(),
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
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

  void _showDetails(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetCtx).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pinned header — always visible regardless of scroll
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 4, 0),
                child: Row(
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
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
              const Text(
                "Equipment Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Divider(),
              // Scrollable content below
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    children: [
                      ...buildDetailRows(item),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}
