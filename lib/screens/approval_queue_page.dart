import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/apiservice.dart';

class ApprovalQueuePage extends StatefulWidget {
  final bool isDark;
  const ApprovalQueuePage({super.key, this.isDark = false});

  @override
  State<ApprovalQueuePage> createState() => _ApprovalQueuePageState();
}

class _ApprovalQueuePageState extends State<ApprovalQueuePage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> allUpdates = [];
  bool isLoading = true;
  String currentRole = 'user';
  String currentUsername = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserRole();
    _fetchUpdates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadUserRole() {
    final box = Hive.box('inspectionBox');
    setState(() {
      currentRole = box.get('role', defaultValue: 'user').toString().toLowerCase().trim();
      currentUsername = box.get('username', defaultValue: '').toString().trim();
    });
  }

  Future<void> _fetchUpdates() async {
    setState(() => isLoading = true);
    try {
      final list = await ApiService.getUpdates();
      setState(() {
        allUpdates = list;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  // Filter updates based on role and tab index
  List<Map<String, dynamic>> _getFilteredUpdates(int tabIndex) {
    if (tabIndex == 0) {
      // Pending review queue
      if (currentRole == 'supervisor') {
        return allUpdates.where((u) => u['status']?.toString().toUpperCase() == 'PENDING').toList();
      } else if (currentRole == 'admin' || currentRole == 'superadmin') {
        return allUpdates.where((u) => u['status']?.toString().toUpperCase() == 'SUPERVISOR_APPROVED').toList();
      } else {
        // Normal user: show their own pending requests
        return allUpdates.where((u) {
          final author = u['inspector_name'] ?? u['inspected_by'] ?? u['created_by'] ?? '';
          final status = u['status']?.toString().toUpperCase() ?? '';
          return author.toString().toLowerCase() == currentUsername.toLowerCase() &&
              (status == 'PENDING' || status == 'SUPERVISOR_APPROVED');
        }).toList();
      }
    } else {
      // History queue (Approved / Rejected)
      if (currentRole == 'supervisor' || currentRole == 'admin' || currentRole == 'superadmin') {
        return allUpdates.where((u) {
          final status = u['status']?.toString().toUpperCase() ?? '';
          return status.contains('APPROVED') || status.contains('REJECTED');
        }).toList();
      } else {
        // Normal user: show their own completed history
        return allUpdates.where((u) {
          final author = u['inspector_name'] ?? u['inspected_by'] ?? u['created_by'] ?? '';
          final status = u['status']?.toString().toUpperCase() ?? '';
          return author.toString().toLowerCase() == currentUsername.toLowerCase() &&
              (status.contains('APPROVED') || status.contains('REJECTED'));
        }).toList();
      }
    }
  }

  Color _getStatusColor(String? status) {
    final s = status?.toUpperCase() ?? '';
    if (s.contains('ADMIN_APPROVED')) return const Color(0xFF1E8E3E); // Deep Green
    if (s.contains('SUPERVISOR_APPROVED')) return const Color(0xFF1A73E8); // Blue
    if (s.contains('REJECTED')) return const Color(0xFFD50000); // Red
    return const Color(0xFFFF8F00); // Pending / Amber
  }

  String _formatStatus(String? status) {
    final s = status?.toUpperCase() ?? 'PENDING';
    return s.replaceAll('_', ' ');
  }

  void _showActionBottomSheet(Map<String, dynamic> update) {
    final updateId = update['id']?.toString() ?? update['update_id']?.toString() ?? '';
    final equipmentId = update['equipment_id']?.toString() ?? update['id']?.toString() ?? 'N/A';
    final proposed = update['proposed_changes'] ?? {};
    final remarks = update['remarks'] ?? proposed['remarks'] ?? 'No inspector remarks provided.';
    final inspectorName = update['inspector_name'] ?? update['created_by'] ?? 'N/A';

    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final double bottomPadding = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Review Update request",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: widget.isDark ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(update['status']?.toString()).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _formatStatus(update['status']?.toString()),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(update['status']?.toString()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildDetailRow("Equipment Code", equipmentId),
              _buildDetailRow("Submitted By", inspectorName),
              _buildDetailRow("Inspector Remarks", remarks),
              
              if (update['supervisor_remarks'] != null)
                _buildDetailRow("Supervisor Remarks", update['supervisor_remarks'].toString()),

              const SizedBox(height: 15),
              Text(
                "Proposed Changes Details:",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark ? Colors.white70 : Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.withOpacity(0.12)),
                ),
                child: proposed.isEmpty
                    ? const Text("No specific field edits.")
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: proposed.entries.map<Widget>((entry) {
                          if (entry.key == 'remarks') return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  "${entry.key.toString().toUpperCase()}: ",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red),
                                ),
                                Text(
                                  entry.value?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: widget.isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 18),
              if (currentRole == 'supervisor' || currentRole == 'admin' || currentRole == 'superadmin') ...[
                TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    hintText: "Add reviewer remarks (Required for rejection)",
                    hintStyle: const TextStyle(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    filled: true,
                    fillColor: widget.isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD50000),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text("REJECT", style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          if (textController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Rejection remarks are required")),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          _processApproval(updateId, false, textController.text.trim());
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E8E3E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text("APPROVE", style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(context);
                          _processApproval(updateId, true, textController.text.trim());
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("CLOSE"),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey),
            ),
          ),
          Expanded(
            flex: 7,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: widget.isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processApproval(String updateId, bool approved, String remarks) async {
    setState(() => isLoading = true);
    bool success = false;
    
    if (currentRole == 'supervisor') {
      success = approved
          ? await ApiService.supervisorApproveUpdate(updateId, remarks)
          : await ApiService.supervisorRejectUpdate(updateId, remarks);
    } else if (currentRole == 'admin' || currentRole == 'superadmin') {
      success = approved
          ? await ApiService.adminApproveUpdate(updateId, remarks)
          : await ApiService.adminRejectUpdate(updateId, remarks);
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: approved ? Colors.green : Colors.red,
          content: Text(approved ? "Update request approved successfully" : "Update request rejected"),
        ),
      );
      _fetchUpdates();
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error processing decision. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageBg = widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final cardBg = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryTextColor = widget.isDark ? Colors.white : const Color(0xFF334155);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: Text(
          currentRole == 'supervisor' || currentRole == 'admin' || currentRole == 'superadmin'
              ? "Approve Console"
              : "My Update Requests",
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
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: primaryTextColor),
            onPressed: _fetchUpdates,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.red,
          unselectedLabelColor: widget.isDark ? Colors.white60 : Colors.blueGrey,
          indicatorColor: Colors.red,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(
              text: currentRole == 'supervisor' || currentRole == 'admin' || currentRole == 'superadmin'
                  ? "Pending Reviews"
                  : "My Pending",
            ),
            Tab(text: "Historical logs"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUpdatesList(_getFilteredUpdates(0), cardBg, primaryTextColor, true),
                _buildUpdatesList(_getFilteredUpdates(1), cardBg, primaryTextColor, false),
              ],
            ),
    );
  }

  Widget _buildUpdatesList(List<Map<String, dynamic>> list, Color cardBg, Color primaryTextColor, bool isPendingTab) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPendingTab ? Icons.done_all_rounded : Icons.history_rounded,
                size: 60,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isPendingTab ? "No updates pending" : "No history logs",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final u = list[index];
        final id = u['equipment_id']?.toString() ?? u['id']?.toString() ?? 'N/A';
        final status = u['status']?.toString() ?? 'PENDING';
        final changes = u['proposed_changes'] ?? {};
        final remarks = u['remarks'] ?? changes['remarks'] ?? 'No remarks';
        final timestamp = u['created_at']?.toString() ?? u['timestamp']?.toString() ?? '';

        return Card(
          color: cardBg,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.grey.withOpacity(0.08), width: 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showActionBottomSheet(u),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Equipment #$id",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: primaryTextColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _formatStatus(status),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: _getStatusColor(status),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Remarks: $remarks",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.change_circle_outlined, size: 14, color: Colors.blueGrey),
                            const SizedBox(width: 5),
                            Text(
                              "${changes.keys.where((k) => k != 'remarks').length} fields modified",
                              style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                            ),
                            if (timestamp.isNotEmpty) ...[
                              const Spacer(),
                              Text(
                                timestamp,
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
