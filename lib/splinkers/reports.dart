import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  final String plant = "Fire Sprinkler";
  final String unit = "Unit 1";

  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateDates();
  }

  void _updateDates() {
    startController.text = DateFormat("dd MMM yyyy").format(startDate);
    endController.text = DateFormat("dd MMM yyyy").format(endDate);
  }

  Future<void> pickDate(bool isStart) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
        _updateDates();
      });
    }
  }

  void generatePDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("PDF Generated")),
    );
  }

  void downloadExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Excel Downloaded")),
    );
  }

  /// 🔲 FIELD BOX
  Widget fieldBox({
    required String label,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.red),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            if (onTap != null)
              const Icon(Icons.calendar_today, size: 18)
          ],
        ),
      ),
    );
  }

  /// 🔘 BUTTON
  Widget actionButton({
    required String text,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(text),
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      /// 🔴 TOP BAR (WHITE BG + RED TEXT)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: const Text(
          "Reports",
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.red),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🧾 HEADER CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.summarize, color: Colors.white, size: 28),
                  SizedBox(width: 10),
                  Text(
                    "Generate Report",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 📦 FORM
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                  )
                ],
              ),
              child: Column(
                children: [

                  /// 🔥 PLANT
                  fieldBox(
                    label: "Plant",
                    value: plant,
                    icon: Icons.local_fire_department,
                  ),

                  const SizedBox(height: 15),

                  /// 🏢 UNIT
                  fieldBox(
                    label: "Unit",
                    value: unit,
                    icon: Icons.apartment,
                  ),

                  const SizedBox(height: 15),

                  /// 📅 FROM DATE
                  fieldBox(
                    label: "From Date",
                    value: startController.text,
                    icon: Icons.date_range,
                    onTap: () => pickDate(true),
                  ),

                  const SizedBox(height: 15),

                  /// 📅 TO DATE
                  fieldBox(
                    label: "To Date",
                    value: endController.text,
                    icon: Icons.calendar_month,
                    onTap: () => pickDate(false),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// 📄 PDF BUTTON
            actionButton(
              text: "Generate PDF",
              color: Colors.red,
              icon: Icons.picture_as_pdf,
              onTap: generatePDF,
            ),

            const SizedBox(height: 12),

            /// 📊 EXCEL BUTTON
            actionButton(
              text: "Download Excel",
              color: Colors.green,
              icon: Icons.table_chart,
              onTap: downloadExcel,
            ),
          ],
        ),
      ),
    );
  }
}