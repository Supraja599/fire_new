import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PlantHealthPage extends StatefulWidget {
  const PlantHealthPage({super.key});

  @override
  State<PlantHealthPage> createState() => _PlantHealthPageState();
}

class _PlantHealthPageState extends State<PlantHealthPage> {
  final List<double> data = [];

  int active = 0;
  int service = 0;
  int inspection = 0;
  int expired = 0;

  @override
  void initState() {
    super.initState();
    _generateData();
  }

  void _generateData() {
    final random = Random();

    for (int i = 0; i < 500; i++) {
      if (i < 450) {
        data.add(85 + random.nextDouble() * 15);
        active++;
      } else if (i < 475) {
        data.add(60 + random.nextDouble() * 15);
        service++;
      } else if (i < 495) {
        data.add(40 + random.nextDouble() * 15);
        inspection++;
      } else {
        data.add(15 + random.nextDouble() * 20);
        expired++;
      }
    }
  }

  double get percentActive => (active / 500) * 100;
  double get percentService => (service / 500) * 100;
  double get percentInspection => (inspection / 500) * 100;
  double get percentExpired => (expired / 500) * 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),

      /// APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Sprinkler Health System",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [

            /// 🔥 FULL COLOR STATUS BOXES (NO DOTS)
            Row(
              children: [
                _statusBox("Active", active, percentActive, Colors.green),
                const SizedBox(width: 8),
                _statusBox("Service", service, percentService, Colors.orange),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _statusBox("Inspect", inspection, percentInspection, Colors.blue),
                const SizedBox(width: 8),
                _statusBox("Expired", expired, percentExpired, Colors.red),
              ],
            ),

            const SizedBox(height: 18),

            /// 📊 GRAPH CONTAINER
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "System Health Trend",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "Total Devices: 500 | Active: $active | Service: $service | Inspect: $inspection | Expired: $expired",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),

                    const SizedBox(height: 12),

                    /// LINE GRAPH
                    Expanded(
                      child: LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: 100,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) =>
                                FlLine(color: Colors.grey.shade200),
                          ),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),

                          lineBarsData: [

                            _line(data.sublist(0, 450), Colors.green),
                            _line(data.sublist(450, 475), Colors.orange),
                            _line(data.sublist(475, 495), Colors.blue),
                            _line(data.sublist(495, 500), Colors.red),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// 📌 PERCENT SUMMARY BAR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _percent("Active", percentActive, Colors.green),
                        _percent("Service", percentService, Colors.orange),
                        _percent("Inspect", percentInspection, Colors.blue),
                        _percent("Expired", percentExpired, Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔳 STATUS BOX (FULL COLOR UI)
  Widget _statusBox(String title, int value, double percent, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
            )
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "$value",
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${percent.toStringAsFixed(1)}%",
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  /// 📈 LINE GRAPH BUILDER
  LineChartBarData _line(List<double> d, Color color) {
    return LineChartBarData(
      spots: List.generate(
        d.length,
            (i) => FlSpot(i.toDouble(), d[i]),
      ),
      isCurved: true,
      color: color,
      barWidth: 3,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.15),
      ),
    );
  }

  /// 📊 PERCENT WIDGET
  Widget _percent(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          "${value.toStringAsFixed(1)}%",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}