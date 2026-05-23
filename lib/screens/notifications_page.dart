import 'package:flutter/material.dart';
import '../services/apiservice.dart';

class NotificationsPage extends StatefulWidget {
  final bool isDark;
  const NotificationsPage({super.key, this.isDark = false});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => isLoading = true);
    try {
      final list = await ApiService.getNotifications();
      setState(() {
        notifications = list;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    final success = await ApiService.markNotificationRead(id);
    if (success) {
      setState(() {
        notifications = notifications.map((n) {
          if (n['id']?.toString() == id) {
            return {...n, 'read': true};
          }
          return n;
        }).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Notification marked as read")),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    final unread = notifications.where((n) => n['read'] != true && n['id'] != null).toList();
    if (unread.isEmpty) return;

    setState(() => isLoading = true);
    for (var n in unread) {
      await ApiService.markNotificationRead(n['id'].toString());
    }
    await _fetchNotifications();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All notifications marked as read")),
    );
  }

  Color _getEventColor(String? event) {
    final ev = event?.toLowerCase() ?? '';
    if (ev.contains('approve') || ev.contains('success')) {
      return const Color(0xFF1E8E3E); // Emerald Green
    }
    if (ev.contains('reject') || ev.contains('fail')) {
      return const Color(0xFFD50000); // Red
    }
    if (ev.contains('create') || ev.contains('pending')) {
      return const Color(0xFF1A73E8); // Blue
    }
    return const Color(0xFFFF8F00); // Amber
  }

  IconData _getEventIcon(String? event) {
    final ev = event?.toLowerCase() ?? '';
    if (ev.contains('approve') || ev.contains('success')) {
      return Icons.check_circle_rounded;
    }
    if (ev.contains('reject') || ev.contains('fail')) {
      return Icons.cancel_rounded;
    }
    if (ev.contains('create') || ev.contains('pending')) {
      return Icons.add_alert_rounded;
    }
    return Icons.notifications_rounded;
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
          "Notifications Feed",
          style: TextStyle(
            color: primaryTextColor,
            fontWeight: FontWeight.w900,
            fontSize: 20,
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
          if (notifications.any((n) => n['read'] != true))
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 18, color: Colors.blue),
              label: const Text("Read All", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: primaryTextColor),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : notifications.isEmpty
              ? _buildEmptyState(secondaryTextColor)
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  color: Colors.red,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      final id = n['id']?.toString() ?? '';
                      final title = n['title']?.toString() ?? 'Update notification';
                      final message = n['message']?.toString() ?? '';
                      final isRead = n['read'] == true;
                      final event = n['event']?.toString() ?? '';
                      final timestamp = n['created_at']?.toString() ?? n['timestamp']?.toString() ?? '';

                      final eventColor = _getEventColor(event);

                      return TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 500)),
                        curve: Curves.easeOutCubic,
                        builder: (context, animValue, child) {
                          return Opacity(
                            opacity: animValue,
                            child: Transform.translate(
                              offset: Offset(0, 30 * (1.0 - animValue)),
                              child: child,
                            ),
                          );
                        },
                        child: Card(
                          color: cardBg,
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: isRead
                                  ? Colors.transparent
                                  : eventColor.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: isRead ? null : () => _markAsRead(id),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: eventColor.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getEventIcon(event),
                                      color: eventColor,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: isRead ? FontWeight.bold : FontWeight.w900,
                                                  color: primaryTextColor,
                                                ),
                                              ),
                                            ),
                                            if (!isRead)
                                              Container(
                                                height: 8,
                                                width: 8,
                                                decoration: BoxDecoration(
                                                  color: eventColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          message,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: secondaryTextColor,
                                            height: 1.4,
                                            fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                                          ),
                                        ),
                                        if (timestamp.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Text(
                                            timestamp,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: secondaryTextColor.withOpacity(0.7),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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
              Icons.notifications_none_rounded,
              size: 70,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "All Caught Up!",
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
              "You have no active system compliance notifications or updates at this time.",
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
