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

    s.forEach((key, val) {
      if (val is num) {
        final intValue = val.toInt();
        final lowerKey = key.toLowerCase();
        if (lowerKey.contains("active") && lowerKey != "active") active = intValue;
        if (lowerKey.contains("expired") && lowerKey != "expired") expired = intValue;
        if (lowerKey.contains("service") && lowerKey != "needs_service") service = intValue;
        if (lowerKey.contains("inspection") && lowerKey != "due_inspection") inspection = intValue;
        if (lowerKey.contains("upcoming") && lowerKey != "upcoming") upcoming = intValue;
      }
    });

    active = active + upcoming;
    final total = active + service + inspection + expired;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Total row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1565C0).withValues(alpha: 0.07),
                  const Color(0xFF1565C0).withValues(alpha: 0.02),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.18), width: 1.3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.leaderboard_rounded, color: Color(0xFF1565C0), size: 16),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "TOTAL UNITS",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1565C0),
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          "Deployed Equipment",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1565C0).withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  isLoading ? "--" : "$total",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1565C0),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 4-count chips row
          Row(
            children: [
              _chip("Active",     active,     const Color(0xFF1E8E3E), Icons.verified_rounded,          isLoading),
              const SizedBox(width: 7),
              _chip("Service",    service,    const Color(0xFFFF8F00), Icons.engineering_rounded,        isLoading),
              const SizedBox(width: 7),
              _chip("Inspection", inspection, const Color(0xFF1565C0), Icons.pending_actions_rounded,    isLoading),
              const SizedBox(width: 7),
              _chip("Expired",    expired,    const Color(0xFFD50000), Icons.report_rounded,             isLoading),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, int count, Color color, IconData icon, bool loading) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.13),
              color.withValues(alpha: 0.04),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.28), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(height: 6),
            Text(
              loading ? "--" : "$count",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.75),
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
