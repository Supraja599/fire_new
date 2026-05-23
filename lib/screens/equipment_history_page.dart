import 'package:flutter/material.dart';
import '../services/apiservice.dart';

class EquipmentHistoryPage extends StatefulWidget {
  final String equipmentId;
  final bool isDark;
  const EquipmentHistoryPage({
    super.key,
    required this.equipmentId,
    this.isDark = false,
  });

  @override
  State<EquipmentHistoryPage> createState() => _EquipmentHistoryPageState();
}

class _EquipmentHistoryPageState extends State<EquipmentHistoryPage> {
  List<Map<String, dynamic>> historyLogs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => isLoading = true);
    try {
      final list = await ApiService.getEquipmentHistory(widget.equipmentId);
      setState(() {
        historyLogs = list;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Color _getEventColor(String eventType) {
    final t = eventType.toLowerCase();
    if (t.contains('admin_approved') || t.contains('final_approved') || t.contains('compliance_pass')) {
      return const Color(0xFF1E8E3E); // Deep Green
    }
    if (t.contains('supervisor_approved')) {
      return const Color(0xFF1A73E8); // Blue
    }
    if (t.contains('reject') || t.contains('fail')) {
      return const Color(0xFFD50000); // Red
    }
    if (t.contains('inspection') || t.contains('check')) {
      return const Color(0xFF3F51B5); // Indigo
    }
    return const Color(0xFFFF8F00); // Amber
  }

  IconData _getEventIcon(String eventType) {
    final t = eventType.toLowerCase();
    if (t.contains('approved')) return Icons.check_circle_rounded;
    if (t.contains('reject')) return Icons.cancel_rounded;
    if (t.contains('inspection') || t.contains('check')) return Icons.assignment_turned_in_rounded;
    return Icons.history_edu_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final pageBg = widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final cardBg = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryTextColor = widget.isDark ? Colors.white : const Color(0xFF334155);
    final secondaryTextColor = widget.isDark ? Colors.white54 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: Text(
          "History Timeline: #${widget.equipmentId}",
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.w900,
            fontSize: 16.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: primaryTextColor),
            onPressed: _fetchHistory,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : historyLogs.isEmpty
              ? _buildEmptyState(secondaryTextColor)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  itemCount: historyLogs.length,
                  itemBuilder: (context, index) {
                    final log = historyLogs[index];
                    final eventType = log['event_type']?.toString() ?? 'Update';
                    final actor = log['performed_by'] ?? log['inspector_name'] ?? 'System';
                    final date = log['date'] ?? log['timestamp'] ?? log['created_at'] ?? '';
                    final remarks = log['remarks'] ?? log['review_remarks'] ?? '';
                    final changes = log['changes'] as Map? ?? {};
                    
                    final color = _getEventColor(eventType);
                    final isLast = index == historyLogs.length - 1;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left side: Visual timeline vertical line and icon indicator
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: color.withOpacity(0.5), width: 1.5),
                                ),
                                child: Icon(
                                  _getEventIcon(eventType),
                                  color: color,
                                  size: 18,
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2.5,
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    color: Colors.grey.withOpacity(0.24),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // Right side: The event card itself
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: Duration(milliseconds: 400 + (index * 60).clamp(0, 600)),
                                curve: Curves.easeOutBack,
                                builder: (context, val, child) {
                                  return Transform.scale(
                                    scale: 0.9 + (val * 0.1),
                                    child: Opacity(opacity: val, child: child),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey.withOpacity(0.08), width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            eventType.replaceAll('_', ' ').toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w900,
                                              color: color,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          if (date.isNotEmpty)
                                            Text(
                                              date,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: secondaryTextColor.withOpacity(0.65),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "By: $actor",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: primaryTextColor,
                                        ),
                                      ),
                                      if (remarks.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          "Remarks: $remarks",
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: secondaryTextColor,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                      if (changes.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: pageBg.withOpacity(0.6),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: changes.entries.map<Widget>((e) {
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 2),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      "${e.key.toString().toUpperCase()}: ",
                                                      style: const TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.blueGrey,
                                                      ),
                                                    ),
                                                    Text(
                                                      e.value?.toString() ?? 'N/A',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: primaryTextColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(Color secondaryTextColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.timeline_rounded,
              size: 70,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "No logs registered",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "There are no audit logs or operational inspection details recorded on this device yet.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: secondaryTextColor.withOpacity(0.7),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
