import 'package:flutter/material.dart';
import '../services/apiservice.dart';

class UserManagementPage extends StatefulWidget {
  final bool isDark;
  const UserManagementPage({super.key, this.isDark = false});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedRoleFilter = "All";

  final List<String> _roles = ["All", "Admin", "Supervisor", "Inspector", "User"];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiService.getAdminUsers();
      setState(() {
        _allUsers = list;
        _applyFilters();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final username = (user['username'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final matchesSearch = name.contains(_searchQuery.toLowerCase()) ||
            username.contains(_searchQuery.toLowerCase()) ||
            email.contains(_searchQuery.toLowerCase());

        if (_selectedRoleFilter == "All") {
          return matchesSearch;
        } else {
          final userRole = (user['role'] ?? '').toString().toLowerCase().trim();
          return matchesSearch && userRole == _selectedRoleFilter.toLowerCase();
        }
      }).toList();
    });
  }

  Color _getRoleColor(String role) {
    final r = role.toLowerCase().trim();
    if (r.contains('admin')) return Colors.red.shade600;
    if (r.contains('supervisor')) return Colors.blue.shade600;
    if (r.contains('inspector')) return Colors.teal.shade600;
    return Colors.green.shade600;
  }

  IconData _getRoleIcon(String role) {
    final r = role.toLowerCase().trim();
    if (r.contains('admin')) return Icons.admin_panel_settings_rounded;
    if (r.contains('supervisor')) return Icons.supervisor_account_rounded;
    if (r.contains('inspector')) return Icons.fact_check_rounded;
    return Icons.person_rounded;
  }

  void _showNavAccessSheet(BuildContext context, Map<String, dynamic> user) {
    final userId = user['id']?.toString() ?? '';
    final username = user['name'] ?? user['username'] ?? 'User';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (c) {
        return Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: FutureBuilder<List<String>>(
            future: ApiService.getUserNavAccess(userId),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  ),
                );
              }

              final modules = snapshot.data ?? [];

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _getRoleColor(user['role'] ?? 'user').withOpacity(0.1),
                        child: Icon(
                          _getRoleIcon(user['role'] ?? 'user'),
                          color: _getRoleColor(user['role'] ?? 'user'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: widget.isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              "User ID: $userId  |  Role: ${(user['role'] ?? 'User').toString().toUpperCase()}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text(
                    "ASSIGNED NAVIGATION TABS",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: widget.isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (modules.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.layers_clear_rounded, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            const Text(
                              "No dynamic modules assigned to this user.",
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: modules.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final mod = modules[index];
                          IconData modIcon = Icons.folder_open_rounded;
                          String friendlyName = mod;

                          if (mod == 'overview') {
                            modIcon = Icons.dashboard_rounded;
                            friendlyName = "Overview Summary";
                          } else if (mod == 'reports') {
                            modIcon = Icons.analytics_rounded;
                            friendlyName = "Audit Reports Viewer";
                          } else if (mod == 'work_orders') {
                            modIcon = Icons.handyman_rounded;
                            friendlyName = "Maintenance Work Orders";
                          } else if (mod == 'add_company') {
                            modIcon = Icons.business_rounded;
                            friendlyName = "Register / Onboard Companies";
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: widget.isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(modIcon, color: Colors.red.shade700, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  friendlyName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: widget.isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = widget.isDark ? const Color(0xFF1E293B) : Colors.white;
    final titleColor = widget.isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "User Directory",
          style: TextStyle(color: titleColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        iconTheme: IconThemeData(color: titleColor),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔎 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _applyFilters();
                });
              },
              style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: "Search user by name, email or role...",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // 🏷️ ROLE FILTER CHIPS
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _roles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final role = _roles[index];
                final isSelected = _selectedRoleFilter == role;
                return ChoiceChip(
                  label: Text(
                    role,
                    style: TextStyle(
                      color: isSelected ? Colors.white : (widget.isDark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedRoleFilter = role;
                        _applyFilters();
                      });
                    }
                  },
                  selectedColor: Colors.red.shade700,
                  backgroundColor: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? Colors.transparent : (widget.isDark ? Colors.white10 : Colors.grey.shade300),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // 📋 USERS LIST
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchUsers,
              color: Colors.red.shade700,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    )
                  : _filteredUsers.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_alt_rounded, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No users found matching your search.",
                                    style: TextStyle(
                                      color: widget.isDark ? Colors.white60 : Colors.grey.shade600,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredUsers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            final roleStr = (user['role'] ?? 'user').toString();
                            final roleColor = _getRoleColor(roleStr);
                            final isActive = user['is_active'] == true;

                            return GestureDetector(
                              onTap: () => _showNavAccessSheet(context, user),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: widget.isDark ? Colors.white10 : Colors.grey.shade100,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(widget.isDark ? 0.2 : 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Left icon avatar
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: roleColor.withOpacity(0.1),
                                      child: Icon(
                                        _getRoleIcon(roleStr),
                                        color: roleColor,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Center details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  user['name'] ?? user['username'] ?? 'User',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: widget.isDark ? Colors.white : Colors.black87,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: isActive
                                                      ? Colors.green.shade50.withOpacity(widget.isDark ? 0.1 : 1)
                                                      : Colors.grey.shade100.withOpacity(widget.isDark ? 0.1 : 1),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  isActive ? "Active" : "Inactive",
                                                  style: TextStyle(
                                                    color: isActive ? Colors.green.shade700 : Colors.grey,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "@${user['username']}",
                                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                                          ),
                                          if (user['company_name'] != null) ...[
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(Icons.business_rounded, color: Colors.grey.shade400, size: 14),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    user['company_name'].toString(),
                                                    style: TextStyle(
                                                      color: widget.isDark ? Colors.white60 : Colors.grey.shade700,
                                                      fontSize: 12,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ]
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Right arrow icon
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
