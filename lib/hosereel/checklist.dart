import 'package:flutter/material.dart';

class ChecklistPage extends StatefulWidget {
  const ChecklistPage({super.key});

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  bool isEditing = false;

  List<Map<String, dynamic>> checklist = [
    {"item": "Location of Hose Reel (Building or Conveyor)", "yes": false, "no": false, "na": false},
    {"item": "Hose reel is securely mounted on the wall.", "yes": false, "no": false, "na": false},
    {"item": "Check for visible damage or corrosion.", "yes": false, "no": false, "na": false},
    {"item": "Inspect hose for cuts, cracks or wear.", "yes": false, "no": false, "na": false},
    {"item": "Check nozzle for blockages or leaks.", "yes": false, "no": false, "na": false},
    {"item": "Pull hose fully to ensure smooth unwinding.", "yes": false, "no": false, "na": false},
    {"item": "Signage above hose reel is visible.", "yes": false, "no": false, "na": false},
    {"item": "Operating instructions label is present.", "yes": false, "no": false, "na": false},
    {"item": "Isolation valve is in good condition.", "yes": false, "no": false, "na": false},
    {"item": "Valve operates smoothly.", "yes": false, "no": false, "na": false},
    {"item": "Retainer clip is present.", "yes": false, "no": false, "na": false},
    {"item": "Hose reel is functional.", "yes": false, "no": false, "na": false},
    {"item": "No replacement required?", "yes": false, "no": false, "na": false},
    {"item": "Mounting bolts are tight.", "yes": false, "no": false, "na": false},
    {"item": "No obstruction for emergency use.", "yes": false, "no": false, "na": false},
    {"item": "Water pressure is adequate.", "yes": false, "no": false, "na": false},
    {"item": "Maintenance record is up to date.", "yes": false, "no": false, "na": false},
    {"item": "No hose kinks or damage.", "yes": false, "no": false, "na": false},
    {"item": "Emergency signage is visible.", "yes": false, "no": false, "na": false},
  ];

  // ================= OPTION BUTTON =================
  Widget optionButton({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: isEditing ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : Colors.grey.shade300,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  // ================= ROW UI =================
  Widget buildRow(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,

        // ⭐ LIGHT BLACK BORDER
        border: Border.all(color: Colors.black12, width: 1),

        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// ITEM TEXT
          Expanded(
            flex: 5,
            child: Text(
              item["item"],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),

          const SizedBox(width: 10),

          /// YES / NO / NA
          Expanded(
            flex: 5,
            child: Row(
              children: [

                optionButton(
                  label: "YES",
                  selected: item["yes"],
                  color: Colors.green,
                  onTap: () {
                    setState(() {
                      item["yes"] = true;
                      item["no"] = false;
                      item["na"] = false;
                    });
                  },
                ),

                optionButton(
                  label: "NO",
                  selected: item["no"],
                  color: Colors.red,
                  onTap: () {
                    setState(() {
                      item["yes"] = false;
                      item["no"] = true;
                      item["na"] = false;
                    });
                  },
                ),

                optionButton(
                  label: "NA",
                  selected: item["na"],
                  color: Colors.orange,
                  onTap: () {
                    setState(() {
                      item["yes"] = false;
                      item["no"] = false;
                      item["na"] = true;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= SNACKBAR =================
  void showToast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      /// APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Hose Reel Checklist",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,

        actions: [
          IconButton(
            icon: Icon(
              isEditing ? Icons.check_circle : Icons.edit,
              color: isEditing ? Colors.green : Colors.blue,
            ),
            onPressed: () {
              setState(() {
                isEditing = !isEditing;
              });

              showToast(
                isEditing ? "Edit Mode ON" : "View Mode",
                isEditing ? Colors.orange : Colors.green,
              );
            },
          )
        ],
      ),

      /// BODY
      body: Column(
        children: [

          const SizedBox(height: 10),

          /// LIST
          Expanded(
            child: ListView.builder(
              itemCount: checklist.length,
              itemBuilder: (context, index) {
                return buildRow(checklist[index]);
              },
            ),
          ),

          /// SAVE BUTTON
          if (isEditing)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  setState(() => isEditing = false);

                  showToast(
                    "Checklist Saved Successfully ✔",
                    Colors.green,
                  );
                },
                child: const Text(
                  "SAVE CHECKLIST",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}