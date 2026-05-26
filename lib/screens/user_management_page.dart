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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (c) {
        return _UserNavAccessSheetContent(
          user: user,
          isDark: widget.isDark,
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

class _UserNavAccessSheetContent extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool isDark;

  const _UserNavAccessSheetContent({
    required this.user,
    required this.isDark,
  });

  @override
  State<_UserNavAccessSheetContent> createState() => _UserNavAccessSheetContentState();
}

class _UserNavAccessSheetContentState extends State<_UserNavAccessSheetContent> {
  List<Map<String, dynamic>> _userModules = [];
  List<Map<String, dynamic>> _allModules = [];
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  int? _selectedModuleId;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userId = widget.user['id']?.toString() ?? '';
    try {
      final results = await Future.wait([
        ApiService.getUserModules(userId),
        ApiService.getAdminModules(),
        ApiService.getAdminUser(userId),
      ]);
      
      setState(() {
        _userModules = results[0] as List<Map<String, dynamic>>;
        _allModules = results[1] as List<Map<String, dynamic>>;
        _userData = results[2] as Map<String, dynamic>?;
        _selectedModuleId = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _resolveModuleMeta(Map<String, dynamic> userMod) {
    final userModId = int.tryParse((userMod['module_id'] ?? userMod['id'] ?? '0').toString()) ?? 0;
    
    // Cross-reference with master modules list
    final match = _allModules.firstWhere(
      (m) {
        final id = int.tryParse((m['id'] ?? m['module_id'] ?? '0').toString()) ?? 0;
        return id == userModId;
      },
      orElse: () => <String, dynamic>{},
    );
    
    final code = (userMod['module_code'] ?? userMod['code'] ?? match['code'] ?? match['module_code'] ?? '').toString();
    final name = userMod['name'] ?? userMod['module_name'] ?? match['name'] ?? match['module_name'] ?? code;
    
    return {
      'id': userModId,
      'code': code,
      'name': name,
    };
  }

  String _getFriendlyModuleName(String code, String fallbackName) {
    final Map<String, String> friendlyNames = {
      'fire_extinguisher': 'Fire Extinguishers',
      'hose_reel': 'Hose Reels',
      'sprinkler': 'Sprinklers',
      'hydrant': 'Fire Hydrants',
      'fire_alarm': 'Alarm Panels',
      'smoke_detector': 'Smoke Detectors',
      'exit_sign': 'Emergency Exits',
      'emergency_light': 'Emergency Lighting',
      'pa_system': 'PA Systems',
      'first_aid_kit': 'First Aid Kits',
      'safety_shower': 'Safety Showers',
      'eyewash_station': 'Eye Wash Stations',
      'spill_kit': 'Spill Kits',
      'ppe_station': 'PPE Cabinets',
      'suppression_system': 'CO2 Systems',
      'fire_blanket': 'Fire Blankets',
      'heat_detector': 'Heat Detectors',
      'co_detector': 'CO Detectors',
      'fire_door': 'Fire Doors',
      'fire_trolley': 'Fire Trolleys',
      'wind_sock': 'Wind Socks',
      'scba_unit': 'SCBA Units',
      'ambulance': 'Ambulance System',
      'muster_point': 'Muster Points',
      'emergency_comm': 'Emergency Communications',
      'signage': 'Safety Signage',
    };
    return friendlyNames[code] ?? (fallbackName.isNotEmpty ? fallbackName : code);
  }

  IconData _getModuleIcon(String code) {
    switch (code) {
      case 'fire_extinguisher': return Icons.fire_extinguisher_rounded;
      case 'hose_reel': return Icons.water_drop_rounded;
      case 'sprinkler': return Icons.shower_rounded;
      case 'hydrant': return Icons.water_damage_rounded;
      case 'fire_alarm': return Icons.alarm_rounded;
      case 'smoke_detector': return Icons.sensors_rounded;
      case 'exit_sign': return Icons.exit_to_app_rounded;
      case 'emergency_light': return Icons.light_mode_rounded;
      case 'pa_system': return Icons.volume_up_rounded;
      case 'first_aid_kit': return Icons.medical_services_rounded;
      case 'safety_shower': return Icons.dry_cleaning_rounded;
      case 'eyewash_station': return Icons.remove_red_eye_rounded;
      case 'spill_kit': return Icons.clean_hands_rounded;
      case 'ppe_station': return Icons.masks_rounded;
      case 'suppression_system': return Icons.co2_rounded;
      case 'fire_blanket': return Icons.layers_rounded;
      case 'heat_detector': return Icons.thermostat_rounded;
      case 'co_detector': return Icons.co2_rounded;
      case 'fire_door': return Icons.door_front_door_rounded;
      case 'fire_trolley': return Icons.airport_shuttle_rounded;
      case 'wind_sock': return Icons.air_rounded;
      case 'scba_unit': return Icons.medical_information_rounded;
      case 'ambulance': return Icons.local_shipping_rounded;
      case 'muster_point': return Icons.group_rounded;
      case 'emergency_comm': return Icons.phone_in_talk_rounded;
      case 'signage': return Icons.warning_rounded;
      default: return Icons.layers_rounded;
    }
  }

  List<Map<String, dynamic>> get _unassignedModules {
    final assignedIds = _userModules.map((m) {
      final meta = _resolveModuleMeta(m);
      return meta['id'] as int;
    }).toSet();
    
    final assignedCodes = _userModules.map((m) {
      final meta = _resolveModuleMeta(m);
      return meta['code'] as String;
    }).where((code) => code.isNotEmpty).toSet();
    
    return _allModules.where((m) {
      final id = int.tryParse((m['id'] ?? m['module_id'] ?? '0').toString()) ?? 0;
      final code = (m['code'] ?? m['module_code'] ?? '').toString();
      return !assignedIds.contains(id) && !assignedCodes.contains(code);
    }).toList();
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

  Future<void> _assignModule() async {
    if (_selectedModuleId == null) return;
    setState(() => _isAssigning = true);
    final userId = widget.user['id']?.toString() ?? '';
    final success = await ApiService.assignUserModule(userId, _selectedModuleId!, "inspect");
    setState(() => _isAssigning = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "Module assigned successfully!" : "Failed to assign module."),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) {
        _loadData();
      }
    }
  }

  Future<void> _deleteModule(int moduleId, String moduleName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirm Revoke"),
        content: Text("Are you sure you want to revoke module '$moduleName' from this user?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Revoke"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final userId = widget.user['id']?.toString() ?? '';
      final success = await ApiService.deleteUserModule(userId, moduleId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? "Module revoked successfully!" : "Failed to revoke module."),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          _loadData();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Resolve fresh user details if loaded, otherwise fall back to local list metadata
    final displayUser = _userData ?? widget.user;
    final userId = displayUser['id']?.toString() ?? widget.user['id']?.toString() ?? '';
    final username = displayUser['username']?.toString() ?? widget.user['username']?.toString() ?? '';
    final name = displayUser['name']?.toString() ?? widget.user['name']?.toString() ?? username;
    final roleStr = displayUser['role']?.toString() ?? widget.user['role']?.toString() ?? 'user';
    final companyName = displayUser['company_name']?.toString() ?? widget.user['company_name']?.toString();
    final roleColor = _getRoleColor(roleStr);

    final subStyle = const TextStyle(color: Colors.grey, fontSize: 12);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
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
                backgroundColor: roleColor.withOpacity(0.1),
                child: Icon(_getRoleIcon(roleStr), color: roleColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      "ID: $userId  |  Username: @$username  |  Role: ${roleStr.toUpperCase()}",
                      style: subStyle,
                    ),
                    if (companyName != null && companyName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.business_rounded, color: Colors.grey.shade400, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              companyName,
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
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          
          if (_isLoading)
            const SizedBox(
              height: 250,
              child: Center(
                child: CircularProgressIndicator(color: Colors.red),
              ),
            )
          else ...[
            // ASSIGNED MODULES LIST
            Text(
              "ASSIGNED MODULES",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: widget.isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            const SizedBox(height: 12),
            if (_userModules.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.layers_clear_rounded, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      const Text(
                        "No modules assigned to this user.",
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
                  itemCount: _userModules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final mod = _userModules[index];
                    final meta = _resolveModuleMeta(mod);
                    final modId = meta['id'] as int;
                    final modCode = meta['code'] as String;
                    final modName = meta['name'] as String;
                    final friendlyName = _getFriendlyModuleName(modCode, modName);
                    final accessLevel = (mod['access_level'] ?? 'inspect').toString();

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(_getModuleIcon(modCode), color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  friendlyName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: widget.isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  "Access Level: ${accessLevel.toUpperCase()}",
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            onPressed: () => _deleteModule(modId, friendlyName),
                            tooltip: "Revoke Access",
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 15),

            // ASSIGN NEW MODULE SECTION
            Text(
              "ASSIGN NEW MODULE",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: widget.isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            const SizedBox(height: 12),
            if (_unassignedModules.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 20),
                    SizedBox(width: 10),
                    Text(
                      "All available modules are assigned to this user.",
                      style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedModuleId,
                      isExpanded: true,
                      dropdownColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
                      style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: widget.isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        hintText: "Select module...",
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      items: _unassignedModules.map((m) {
                        final mId = int.tryParse((m['id'] ?? m['module_id'] ?? '0').toString()) ?? 0;
                        final mCode = (m['code'] ?? m['module_code'] ?? '').toString();
                        final mName = m['name'] ?? m['module_name'] ?? mCode;
                        final friendly = _getFriendlyModuleName(mCode, mName);
                        return DropdownMenuItem<int>(
                          value: mId,
                          child: Row(
                            children: [
                              Icon(_getModuleIcon(mCode), color: Colors.red.shade700, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  friendly,
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedModuleId = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_selectedModuleId == null || _isAssigning) ? null : _assignModule,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isAssigning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text("Assign", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
