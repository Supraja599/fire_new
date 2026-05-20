import 'package:flutter/material.dart';

class StatusCountStrip extends StatelessWidget {
  final Map<String, dynamic>? summary;
  final bool isLoading;

  const StatusCountStrip({super.key, this.summary, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final s = summary ?? {};
    int upcoming = (s["upcoming"] ?? s["upcoming_units"] ?? 0) as int;
    int active = (s["active_units"] ?? s["active"] ?? s["active_loops"] ?? 0) as int;
    int service = (s["needs_service"] ?? s["needs_service_units"] ?? 0) as int;
    int inspection = (s["due_inspection"] ?? s["due_inspection_units"] ?? s["due_inspection_loops"] ?? 0) as int;
    int expired = (s["expired"] ?? s["expired_units"] ?? s["expired_loops"] ?? 0) as int;
    int total = (s["total"] ?? s["total_units"] ?? s["total_loops"] ?? s["total_extinguishers"] ?? 0) as int;

    // Dynamic suffix pattern matching fallback for all modules (e.g. _extinguishers, _loops, etc.)
    s.forEach((key, val) {
      if (val is num) {
        final intValue = val.toInt();
        final lowerKey = key.toLowerCase();
        if (lowerKey.contains("active") && lowerKey != "active") active = intValue;
        if (lowerKey.contains("total") && lowerKey != "total") total = intValue;
        if (lowerKey.contains("expired") && lowerKey != "expired") expired = intValue;
        if (lowerKey.contains("service") && lowerKey != "needs_service") service = intValue;
        if (lowerKey.contains("inspection") && lowerKey != "due_inspection") inspection = intValue;
        if (lowerKey.contains("upcoming") && lowerKey != "upcoming") upcoming = intValue;
      }
    });

    active = active + upcoming;
    total = active + service + inspection + expired;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Total row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "TOTAL UNITS",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF5F6368), letterSpacing: 0.4),
                ),
                Text(
                  isLoading ? "--" : "$total",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF202124)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 4-count chips row
          Row(
            children: [
              _chip("Active",     active,     const Color(0xFF1E8E3E), Icons.check_circle_outline),
              const SizedBox(width: 7),
              _chip("Service",    service,    const Color(0xFFFF8F00), Icons.build_outlined),
              const SizedBox(width: 7),
              _chip("Inspection", inspection, const Color(0xFF1565C0), Icons.fact_check_outlined),
              const SizedBox(width: 7),
              _chip("Expired",    expired,    const Color(0xFFD50000), Icons.warning_amber_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              isLoading ? "--" : "$count",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.85)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
