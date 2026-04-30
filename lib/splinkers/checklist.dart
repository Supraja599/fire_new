import 'package:flutter/material.dart';

class ChecklistPage extends StatefulWidget {
  const ChecklistPage({super.key});

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  late List<Map<String, dynamic>> checklist;

  @override
  void initState() {
    super.initState();
    checklist = _buildChecklist();
  }

  /// ✅ YOUR EXACT CHECKLIST (NO CHANGES)
  List<Map<String, dynamic>> _buildChecklist() {
    final items = [
      "Ensure all control valves are open, locked, sealed, and properly labeled",
      "Verify tamper switches and supervisory alarms are functional",
      "Ensure valve areas are accessible and well maintained",
      "Check pressure gauges are installed, readable, calibrated, and within limits",
      "Ensure sprinkler heads are clean, undamaged, correctly installed, and properly spaced",
      "Verify correct temperature rating and color coding of sprinkler heads",
      "Maintain minimum clearance and ensure no obstruction to spray pattern",
      "Keep spare sprinkler heads and wrench available",
      "Inspect piping for leaks, corrosion, damage, and unauthorized modifications",
      "Ensure proper pipe supports, spacing, and seismic bracing",
      "Verify pipelines are properly identified (fire line marking)",
      "Ensure proper slope in dry systems",
      "Test water flow and verify alarm activation and signal transmission",
      "Ensure alarms are audible, visible, and responsive",
      "Check flow switches and system integration",
      "Ensure adequate and reliable water supply with sufficient pressure and flow",
      "Verify fire water storage and dedicated supply system",
      "Ensure all supply valves are open and unobstructed",
      "Verify fire pump automatic operation, pressure performance, and regular testing",
      "Ensure adequate fuel/power supply and proper pump room conditions",
      "Check dry system components including air compressor, pressure, and alarms",
      "Verify antifreeze systems where applicable",
      "Inspect backflow preventer operation, leakage condition, and certification",
      "Ensure no unauthorized bypass connections",
      "Verify fire department connection accessibility, condition, and identification",
      "Conduct main drain test and compare pressure readings with previous records",
      "Ensure fire alarm panel operation, system integration, wiring, and backup power",
      "Verify hazard classification, sprinkler spacing, and system design compliance",
      "Ensure no changes affecting system performance (storage, occupancy, layout)",
      "Maintain all inspection, testing, maintenance records, and compliance certificates",
      "Ensure compliance with NFPA, ISO, BIS / NBC standards",
      "Ensure clear access, proper signage, and housekeeping around fire systems",
      "Record defects, recommend corrective actions, verify repairs",
    ];

    return items
        .map((e) => {
      "item": e,
      "yes": false,
      "no": false,
      "na": false,
    })
        .toList();
  }

  void _setValue(int index, String type) {
    setState(() {
      checklist[index]["yes"] = type == "YES";
      checklist[index]["no"] = type == "NO";
      checklist[index]["na"] = type == "NA";
    });
  }

  Color _statusColor(Map item) {
    if (item["yes"]) return Colors.green;
    if (item["no"]) return Colors.red;
    if (item["na"]) return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),

      /// 🔙 APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Fire Sprinkler Checklist",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      /// 📋 LIST
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: checklist.length,
        itemBuilder: (context, index) {
          final item = checklist[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _statusColor(item).withOpacity(0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                )
              ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 🔹 TITLE + STATUS DOT
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _statusColor(item),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item["item"],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /// 🔘 BUTTONS
                Row(
                  children: [
                    _btn(index, "YES", Colors.green),
                    const SizedBox(width: 8),
                    _btn(index, "NO", Colors.red),
                    const SizedBox(width: 8),
                    _btn(index, "NA", Colors.orange),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 🔘 BUTTON UI
  Widget _btn(int index, String label, Color color) {
    final item = checklist[index];

    bool selected = false;
    if (label == "YES") selected = item["yes"];
    if (label == "NO") selected = item["no"];
    if (label == "NA") selected = item["na"];

    return Expanded(
      child: GestureDetector(
        onTap: () => _setValue(index, label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}