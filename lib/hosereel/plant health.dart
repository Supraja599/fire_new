import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fire_new/hosereel/services/apiservice.dart';

enum ChartType { bar, line, pie }

class PlantHealthScreen extends StatefulWidget {
  const PlantHealthScreen({Key? key}) : super(key: key);

  @override
  State<PlantHealthScreen> createState() => _PlantHealthScreenState();
}

class _PlantHealthScreenState extends State<PlantHealthScreen> {

  final api = HoseReelApiService();

  int active = 0;
  int needsService = 0;
  int dueInspection = 0;
  int expired = 0;

  bool isLoading = true;
  ChartType selectedChart = ChartType.bar;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final results = await Future.wait([
      api.getActiveCount(),
      api.getNeedsServiceCount(),
      api.getDueInspectionCount(),
      api.getExpiredCount(),
    ]);

    setState(() {
      active = results[0];
      needsService = results[1];
      dueInspection = results[2];
      expired = results[3];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final total = active + needsService + dueInspection + expired;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text("Plant Health"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

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

  // ================= CARD =================
  Widget _card(String title, int value, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () {

          String status = "";

          if (title == "Active") status = "active";
          if (title == "Service") status = "needs-service";
          if (title == "Inspect") status = "due-inspection";
          if (title == "Expired") status = "expired";

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HoseListPage(status: status),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.7), color],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(title, style: const TextStyle(color: Colors.white70)),
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
      ),
    );
  }

  // ================= TOGGLE =================
  Widget _toggle(String text, ChartType type) {
    final isSelected = selectedChart == type;

    return GestureDetector(
      onTap: () => setState(() => selectedChart = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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

  // ================= CHART =================
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

  // ================= BAR =================
  Widget _barChart() => BarChart(
    BarChartData(
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              switch (value.toInt()) {
                case 0: return _label("Active");
                case 1: return _label("Service");
                case 2: return _label("Inspect");
                case 3: return _label("Expired");
                default: return const Text("");
              }
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

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(text, style: const TextStyle(fontSize: 10)),
  );

  BarChartGroupData _bar(int x, int value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value.toDouble(),
          color: color,
          width: 18,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  // ================= LINE =================
  Widget _lineChart() => LineChart(
    LineChartData(
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              switch (value.toInt()) {
                case 0: return _label("Active");
                case 1: return _label("Service");
                case 2: return _label("Inspect");
                case 3: return _label("Expired");
                default: return const Text("");
              }
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          isCurved: true,
          barWidth: 4,
          dotData: FlDotData(show: true),
          spots: [
            FlSpot(0, active.toDouble()),
            FlSpot(1, needsService.toDouble()),
            FlSpot(2, dueInspection.toDouble()),
            FlSpot(3, expired.toDouble()),
          ],
        )
      ],
    ),
  );

  // ================= PIE =================
  Widget _pieChart(int total) => Center(
    child: SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sections: [
            _pie("Active", active, total, Colors.green),
            _pie("Service", needsService, total, Colors.orange),
            _pie("Inspect", dueInspection, total, Colors.blue),
            _pie("Expired", expired, total, Colors.red),
          ],
        ),
      ),
    ),
  );

  PieChartSectionData _pie(String label, int value, int total, Color color) {
    final percent = total == 0 ? 0 : (value / total) * 100;

    return PieChartSectionData(
      value: value.toDouble(),
      color: color,
      radius: 55,
      title: "${percent.toStringAsFixed(0)}%\n$label",
      titleStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
// SECOND PAGE
//////////////////////////////////////////////////////////////

class HoseListPage extends StatefulWidget {
  final String status;

  const HoseListPage({super.key, required this.status});

  @override
  State<HoseListPage> createState() => _HoseListPageState();
}

class _HoseListPageState extends State<HoseListPage> {

  final api = HoseReelApiService();

  List<dynamic> list = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    final data = await api.getByStatus(widget.status);

    setState(() {
      list = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(widget.status.toUpperCase())),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: list.length,
        itemBuilder: (_, i) {

          final item = list[i];
          final id = item["sos_id"] ?? item["id"] ?? "No ID";

          final location =
              item["location"] ??
                  item["zone"] ??
                  item["building"] ??
                  "Zone A";

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: const Icon(Icons.fire_hydrant_alt, color: Colors.red),
              title: Text("SOS ID: $id"),
              subtitle: Text(location),

              onTap: () => _showDetails(item),
            ),
          );
        },
      ),
    );
  }

  void _showDetails(Map item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Details"),
        content: SingleChildScrollView(
          child: Column(
            children: item.entries.map((e) {
              return Row(
                children: [
                  Expanded(child: Text(e.key)),
                  Expanded(child: Text(e.value.toString())),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}