import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fire_new/widgets/equipment_list_page.dart';

class SafetyGaugeWidget extends StatefulWidget {
  final int active;
  final int expired;
  final int needsService;
  final int inspection;
  final int health;
  final String moduleName;
  final dynamic api;

  const SafetyGaugeWidget({
    super.key,
    required this.active,
    required this.expired,
    required this.needsService,
    required this.inspection,
    required this.health,
    required this.moduleName,
    required this.api,
  });

  @override
  State<SafetyGaugeWidget> createState() => _SafetyGaugeWidgetState();
}

class _SafetyGaugeWidgetState extends State<SafetyGaugeWidget> {
  int touchedIndex = -1;
  bool _isLoading = false;

  String _getImagePath() {
    final Map<String, String> imageMap = {
      "Hydrant": "assets/firehydrant.webp",
      "Emergency Exits": "assets/emergency_exit.webp",
      "Sprinklers": "assets/sprinkler.webp",
      "Fire Extinguisher": "assets/extinguisher.webp",
      "Alarm Panel": "assets/alarm_panel.webp",
    };
    if (imageMap.containsKey(widget.moduleName)) return imageMap[widget.moduleName]!;
    return "assets/${widget.moduleName.toLowerCase().replaceAll(' ', '_')}.webp";
  }

  Future<void> _navigateTo(BuildContext context, String title, Color color, Future<List<Map<String, dynamic>>> Function() fetcher) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    // Show a loading snackbar
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            const SizedBox(width: 15),
            Text("Fetching $title..."),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 10),
      ),
    );

    try {
      final items = await fetcher();
      if (!mounted) return;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      
      Navigator.push(context, MaterialPageRoute(builder: (_) => EquipmentListPage(
        title: "$title - ${widget.moduleName}",
        color: color,
        items: items,
        imagePath: _getImagePath(),
        fallbackIcon: Icons.security,
      )));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error fetching data.")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int total = widget.active + widget.expired + widget.needsService + widget.inspection;
    if (total == 0) total = 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "SYSTEM READINESS",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          final idx = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          touchedIndex = idx;
                          
                          if (event is FlTapUpEvent && !_isLoading) {
                            if (idx == 0) _navigateTo(context, "Active Units", Colors.green, () => widget.api.getActive());
                            else if (idx == 1) _navigateTo(context, "Needs Service", Colors.amber.shade700, () => widget.api.getNeedsService());
                            else if (idx == 2) _navigateTo(context, "Inspection Due", Colors.blue, () => widget.api.getDueInspection());
                            else if (idx == 3) _navigateTo(context, "Expired Units", Colors.red, () => widget.api.getExpired());
                          }
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 4,
                    centerSpaceRadius: 60,
                    sections: [
                      PieChartSectionData(
                        color: Colors.green.shade500,
                        value: widget.active > 0 ? widget.active.toDouble() : 0.01,
                        title: '',
                        radius: touchedIndex == 0 ? 30.0 : 22.0,
                      ),
                      PieChartSectionData(
                        color: Colors.amber.shade500,
                        value: widget.needsService > 0 ? widget.needsService.toDouble() : 0.01,
                        title: '',
                        radius: touchedIndex == 1 ? 30.0 : 22.0,
                      ),
                      PieChartSectionData(
                        color: Colors.blue.shade500,
                        value: widget.inspection > 0 ? widget.inspection.toDouble() : 0.01,
                        title: '',
                        radius: touchedIndex == 2 ? 30.0 : 22.0,
                      ),
                      PieChartSectionData(
                        color: Colors.red.shade600,
                        value: widget.expired > 0 ? widget.expired.toDouble() : 0.01,
                        title: '',
                        radius: touchedIndex == 3 ? 30.0 : 22.0,
                      ),
                    ],
                  ),
                ),
                // Center text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${widget.health}%",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const Text(
                      "HEALTH",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          // Legend Cards
          Row(
            children: [
              _buildLegend("Active", widget.active, Colors.green.shade600),
              _buildLegend("Service", widget.needsService, Colors.amber.shade600),
              _buildLegend("Inspect", widget.inspection, Colors.blue.shade600),
              _buildLegend("Expired", widget.expired, Colors.red.shade600),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegend(String label, int value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color.withOpacity(0.8), letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
