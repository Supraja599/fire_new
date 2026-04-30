import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

enum ChartType { bar, line, pie }

class PlantHealthScreen extends StatefulWidget {
  const PlantHealthScreen({Key? key}) : super(key: key);

  @override
  State<PlantHealthScreen> createState() => _PlantHealthScreenState();
}

class _PlantHealthScreenState extends State<PlantHealthScreen> {
  final int active = 380;
  final int needsService = 60;
  final int dueInspection = 40;
  final int expired = 20;

  ChartType selectedChart = ChartType.bar;

  @override
  Widget build(BuildContext context) {
    final total = active + needsService + dueInspection + expired;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🔥 TOP CARDS (IMPROVED)
            Row(
              children: [
                _card("Active", active, Colors.green),
                const SizedBox(width: 10),
                _card("Service", needsService, Colors.orange),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _card("Inspect", dueInspection, Colors.blue),
                const SizedBox(width: 10),
                _card("Expired", expired, Colors.red),
              ],
            ),

            const SizedBox(height: 20),

            /// 🔷 TOGGLE
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6)
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _toggle("Bar", ChartType.bar),
                  _toggle("Line", ChartType.line),
                  _toggle("Pie", ChartType.pie),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(child: _buildChart(total)),
          ],
        ),
      ),
    );
  }

  /// 🔥 CARD (added shadow)
  Widget _card(String title, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.7), color],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔷 TOGGLE
  Widget _toggle(String text, ChartType type) {
    final isSelected = selectedChart == type;

    return GestureDetector(
      onTap: () => setState(() => selectedChart = type),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildChart(int total) {
    switch (selectedChart) {
      case ChartType.bar:
        return _barChart();
      case ChartType.line:
        return _lineChart();
      case ChartType.pie:
        return _pieChart(total);
    }
  }

  /// 📊 BAR (better spacing)
  Widget _barChart() {
    final labels = ["Active", "Service", "Inspect", "Expired"];

    return BarChart(
      BarChartData(
        maxY: 400,
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),

        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 100,
              reservedSize: 40, // ✅ FIX spacing
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    labels[value.toInt()],
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ),

        barGroups: [
          _bar(0, active, Colors.green),
          _bar(1, needsService, Colors.orange),
          _bar(2, dueInspection, Colors.blue),
          _bar(3, expired, Colors.red),
        ],
      ),
    );
  }

  BarChartGroupData _bar(int x, int value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value.toDouble(),
          width: 22,
          borderRadius: BorderRadius.circular(8),
          color: color,
        ),
      ],
    );
  }

  /// 📈 LINE (better dots)
  Widget _lineChart() {
    final labels = ["Active", "Service", "Inspect", "Expired"];

    return LineChart(
      LineChartData(
        maxY: 400,
        gridData: FlGridData(show: false),

        titlesData: FlTitlesData(
          leftTitles:
          AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(labels[value.toInt()],
                      style: const TextStyle(fontSize: 11)),
                );
              },
            ),
          ),
        ),

        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: Colors.blue,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            spots: [
              FlSpot(0, active.toDouble()),
              FlSpot(1, needsService.toDouble()),
              FlSpot(2, dueInspection.toDouble()),
              FlSpot(3, expired.toDouble()),
            ],
          ),
        ],
      ),
    );
  }

  /// 🥧 PIE (FIXED OVERFLOW TEXT)
  Widget _pieChart(int total) {
    return PieChart(
      PieChartData(
        centerSpaceRadius: 40,
        sectionsSpace: 4,
        sections: [
          _pie(active, total, Colors.green, "Active"),
          _pie(needsService, total, Colors.orange, "Service"),
          _pie(dueInspection, total, Colors.blue, "Inspect"),
          _pie(expired, total, Colors.red, "Expired"),
        ],
      ),
    );
  }

  PieChartSectionData _pie(
      int value, int total, Color color, String label) {
    final percent = (value / total) * 100;

    return PieChartSectionData(
      value: value.toDouble(),
      color: color,
      radius: 80,
      title: "$label\n${percent.toStringAsFixed(0)}%",
      titleStyle: const TextStyle(
        fontSize: 10, // ✅ prevent overlap
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}