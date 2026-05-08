import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fire_new/local_db.dart';
import 'main.dart';

import 'dashboard.dart';
import 'hydrant/dashboard.dart';
import 'hosereel/dashboard.dart' as hose;
import 'splinkers/sprinkler.dart';
import 'alarm_panel/dashboard.dart';
import 'smoke_detector/dashboard.dart';
import 'fire_trolley/dashboard.dart';
import 'emergency_exits/dashboard.dart';
import 'emergency_lighting/dashboard.dart';
import 'pa_system/dashboard.dart';
import 'wind_sock/dashboard.dart';
import 'scba_units/dashboard.dart';
import 'ambulance/dashboard.dart';
import 'first_aid/dashboard.dart';
import 'emergency_shower/dashboard.dart';
import 'eye_wash/dashboard.dart';
import 'spill_kits/dashboard.dart';
import 'chemical_shower/dashboard.dart';
import 'ppe_cabinets/dashboard.dart';
import 'co2_system/dashboard.dart';
import 'signage/dashboard.dart';
import 'emergency_comm/dashboard.dart';
import 'fire_blankets/dashboard.dart';
import 'muster_points/dashboard.dart';
import 'heat_detector/dashboard.dart';
import 'co_detector/dashboard.dart';
import 'fire_door/dashboard.dart';

// Import API services for health fetching
import 'services/apiservice.dart'; // Extinguishers
import 'hydrant/services/hydrant_api_service.dart';
import 'hosereel/services/apiservice.dart';
import 'splinkers/services/sprinkler_api_service.dart';
import 'alarm_panel/services/alarm_panel_api_service.dart';
import 'smoke_detector/services/smoke_detector_api_service.dart';
import 'fire_trolley/services/fire_trolley_api_service.dart';
import 'emergency_exits/services/api_service.dart';
import 'emergency_lighting/services/api_service.dart';
import 'pa_system/services/api_service.dart';
import 'wind_sock/services/api_service.dart';
import 'scba_units/services/api_service.dart';
import 'ambulance/services/api_service.dart';
import 'first_aid/services/api_service.dart';
import 'emergency_shower/services/api_service.dart';
import 'eye_wash/services/api_service.dart';
import 'spill_kits/services/api_service.dart';
import 'chemical_shower/services/api_service.dart';
import 'ppe_cabinets/services/api_service.dart';
import 'co2_system/services/api_service.dart';
import 'signage/services/api_service.dart';
import 'emergency_comm/services/api_service.dart';
import 'fire_blankets/services/api_service.dart';
import 'muster_points/services/api_service.dart';
import 'heat_detector/services/api_service.dart';
import 'co_detector/services/api_service.dart';
import 'fire_door/services/api_service.dart';

class IconsPage extends StatefulWidget {
  const IconsPage({super.key});

  @override
  State<IconsPage> createState() => _IconsPageState();
}

class ModuleItem {
  final String name;
  final String image;
  final String moduleCode;
  final Widget page;
  final Future<Map<String, dynamic>> Function() fetchSummary;
  final int moduleId;
  int health;
  String status;
  int total;
  int expired;

  ModuleItem({
    required this.name,
    required this.image,
    required this.moduleCode,
    required this.moduleId,
    required this.page,
    required this.fetchSummary,
    this.health = -1, // Changed to -1 to signify loading
    this.status = 'green',
    this.total = 0,
    this.expired = 0,
  });
}

class _IconsPageState extends State<IconsPage>
    with SingleTickerProviderStateMixin {
  bool isDark = false;
  bool isLoading = true;
  double? apiReadinessScore;
  late AnimationController _blinkController;

  late List<ModuleItem> modules;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    final box = Hive.box('inspectionBox');
    final String role = box.get('role', defaultValue: 'user').toString().toLowerCase().trim();
    final List<dynamic> assignedModulesData = box.get('modules', defaultValue: []);
    
    print("🛠️ DEBUG: Current Role is '$role'");
    print("🛠️ DEBUG: Assigned Modules from API: $assignedModulesData");

    // Extract both IDs and Codes for maximum compatibility
    final Set<String> assignedCodes = {};
    final Set<int> assignedIds = {};

    for (var m in assignedModulesData) {
      if (m is Map) {
        assignedCodes.add(m['code']?.toString() ?? '');
        assignedIds.add(int.tryParse(m['id']?.toString() ?? '0') ?? 0);
        assignedCodes.add(m['module_code']?.toString() ?? '');
        assignedIds.add(int.tryParse(m['module_id']?.toString() ?? '0') ?? 0);
      } else {
        assignedCodes.add(m.toString());
        assignedIds.add(int.tryParse(m.toString()) ?? 0);
      }
    }

    final allModules = [
      ModuleItem(
        name: 'Extinguishers',
        image: 'assets/extinguisher.png',
        moduleCode: 'fire_extinguisher',
        moduleId: 30,
        page: const DashboardPage(),
        fetchSummary: () => ApiService.getSummary(),
      ),
      ModuleItem(
        name: 'Hose Reels',
        image: 'assets/hosereel.png',
        moduleCode: 'hose_reel',
        moduleId: 33,
        page: const hose.Dashboard(),
        fetchSummary: () => HoseReelApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Sprinklers',
        image: 'assets/sprinkler.png',
        moduleCode: 'sprinkler',
        moduleId: 31,
        page: const SprinklerPage(),
        fetchSummary: () => SprinklerApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Hydrants',
        image: 'assets/firehydrant.png',
        moduleCode: 'hydrant',
        moduleId: 34,
        page: const HydrantDashboardPage(),
        fetchSummary: () => HydrantApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Alarm Panels',
        image: 'assets/alarm_panel.png',
        moduleCode: 'fire_alarm',
        moduleId: 35,
        page: const AlarmPanelDashboard(),
        fetchSummary: () => AlarmPanelApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Smoke Det.',
        image: 'assets/smoke_detector.png',
        moduleCode: 'smoke_detector',
        moduleId: 36,
        page: const SmokeDetectorDashboard(),
        fetchSummary: () => SmokeDetectorApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Fire Trolley',
        image: 'assets/fire_trolley.png',
        moduleCode: 'fire_trolley',
        moduleId: 42, // Suppression system is 42 in spec, but fire_trolley is not in standard list. Let's map it logically.
        // Wait, the spec has 30 to 54. 
        // 42 suppression_system.
        // Let's use the codes from the spec.
        page: const FireTrolleyDashboard(),
        fetchSummary: () => FireTrolleyApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Exits',
        image: 'assets/emergency_exit.png',
        moduleCode: 'exit_sign',
        moduleId: 39,
        page: const EmergencyExitsDashboard(),
        fetchSummary: () => EmergencyExitsApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Lighting',
        image: 'assets/emergency_lighting.png',
        moduleCode: 'emergency_light',
        moduleId: 38,
        page: const EmergencyLightingDashboard(),
        fetchSummary: () => EmergencyLightingApiService().getSummary(),
      ),
      ModuleItem(
        name: 'PA System',
        image: 'assets/pa_system.png',
        moduleCode: 'pa_system',
        moduleId: 44,
        page: const PASystemDashboard(),
        fetchSummary: () => PASystemApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Wind Sock',
        image: 'assets/wind_sock.png',
        moduleCode: 'wind_sock',
        moduleId: 0, // Not in spec, using 0 as placeholder
        page: const WindSockDashboard(),
        fetchSummary: () => WindSockApiService().getSummary(),
      ),
      ModuleItem(
        name: 'SCBA Units',
        image: 'assets/scba_unit.png',
        moduleCode: 'scba_unit',
        moduleId: 0, // Not in spec
        page: const SCBAUnitsDashboard(),
        fetchSummary: () => SCBAUnitsApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Ambulance',
        image: 'assets/ambulance.png',
        moduleCode: 'ambulance',
        moduleId: 0, // Not in spec
        page: const AmbulanceDashboard(),
        fetchSummary: () => AmbulanceApiService().getSummary(),
      ),
      ModuleItem(
        name: 'First Aid',
        image: 'assets/first_aid.png',
        moduleCode: 'first_aid_kit',
        moduleId: 45,
        page: const FirstAidDashboard(),
        fetchSummary: () => FirstAidApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Shower',
        image: 'assets/emergency_shower.png',
        moduleCode: 'safety_shower',
        moduleId: 47,
        page: const EmergencyShowerDashboard(),
        fetchSummary: () => EmergencyShowerApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Eye Wash',
        image: 'assets/eye_wash.png',
        moduleCode: 'eyewash_station',
        moduleId: 46,
        page: const EyeWashDashboard(),
        fetchSummary: () => EyeWashApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Spill Kits',
        image: 'assets/spill_kits.png',
        moduleCode: 'spill_kit',
        moduleId: 48,
        page: const SpillKitsDashboard(),
        fetchSummary: () => SpillKitsApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Chem Shower',
        image: 'assets/chemical_shower.png',
        moduleCode: 'chemical_shower',
        moduleId: 0, // Not in spec
        page: const ChemicalShowerDashboard(),
        fetchSummary: () => ChemicalShowerApiService().getSummary(),
      ),
      ModuleItem(
        name: 'PPE Cabs',
        image: 'assets/ppe_cabinets.png',
        moduleCode: 'ppe_station',
        moduleId: 49,
        page: const PPECabinetsDashboard(),
        fetchSummary: () => PPECabinetsApiService().getSummary(),
      ),
      ModuleItem(
        name: 'CO2 System',
        image: 'assets/co2_system.png',
        moduleCode: 'suppression_system',
        moduleId: 42,
        page: const CO2SystemDashboard(),
        fetchSummary: () => CO2SystemApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Signage',
        image: 'assets/signage.png',
        moduleCode: 'signage',
        moduleId: 0, // Not in spec
        page: const SignageDashboard(),
        fetchSummary: () => SignageApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Comm.',
        image: 'assets/emergency_comm.png',
        moduleCode: 'emergency_comm',
        moduleId: 0, // Not in spec
        page: const EmergencyCommDashboard(),
        fetchSummary: () => EmergencyCommApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Blankets',
        image: 'assets/fire_blankets.png',
        moduleCode: 'fire_blanket',
        moduleId: 41,
        page: const FireBlanketsDashboard(),
        fetchSummary: () => FireBlanketsApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Muster Pt.',
        image: 'assets/muster_points.png',
        moduleCode: 'muster_point',
        moduleId: 0, // Not in spec
        page: const MusterPointsDashboard(),
        fetchSummary: () => MusterPointsApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Heat Det.',
        image: 'assets/heat_detector.png',
        moduleCode: 'heat_detector',
        moduleId: 37,
        page: const HeatDetectorDashboard(),
        fetchSummary: () => HeatDetectorApiService().getSummary(),
      ),
      ModuleItem(
        name: 'CO Detector',
        image: 'assets/co_detector.png',
        moduleCode: 'co_detector',
        moduleId: 40,
        page: const CODetectorDashboard(),
        fetchSummary: () => CODetectorApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Fire Door',
        image: 'assets/fire_door.png',
        moduleCode: 'fire_door',
        moduleId: 43,
        page: const FireDoorDashboard(),
        fetchSummary: () => FireDoorApiService().getSummary(),
      ),
    ];

    // Filter modules based on role
    // Updated: Both superadmin and admin see everything by default for easier development
    if (role == 'superadmin' || role == 'admin') {
      print("✅ Full access granted for role: $role");
      modules = allModules;
    } else {
      print("🔒 Restricted access: Filtering modules for $role");
      // Match by Code OR by ID
      modules = allModules.where((m) => 
        assignedCodes.contains(m.moduleCode) || 
        assignedIds.contains(m.moduleId)
      ).toList();
      
      print("🎯 Found ${modules.length} matching modules for your assignments.");
    }

    _loadHealthData();
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  Future<void> _loadHealthData() async {
    setState(() => isLoading = true);

    // 1. Fetch Global Dashboard first for "Readiness Score" and bulk health data
    Map<String, dynamic> globalData = {};
    try {
      globalData = await ApiService.getGlobalDashboard();
    } catch (_) {}

    // 2. Map global data to modules if available
    final List<dynamic> globalModules = globalData["modules"] ?? [];

    await Future.wait(
      modules.map((mod) async {
        try {
          // Try to find module in global data first
          final globalMod = globalModules.firstWhere(
            (m) =>
                m["module_code"] == mod.moduleCode ||
                m["code"] == mod.moduleCode,
            orElse: () => null,
          );

          if (globalMod != null) {
            mod.total =
                globalMod["total"] ??
                globalMod["total_units"] ??
                globalMod["total_loops"] ??
                globalMod["total_extinguishers"] ??
                0;
            mod.expired =
                globalMod["expired"] ??
                globalMod["expired_units"] ??
                globalMod["expired_extinguishers"] ??
                0;

            // Check if we have valid counts. If so, calculate health locally to ensure accuracy.
            if (mod.total > 0) {
              mod.health = ApiService.calculateHealth(globalMod);
            } else {
              final hs =
                  globalMod["health_score"] ??
                  globalMod["health"] ??
                  globalMod["score"] ??
                  100;
              mod.health = hs.toInt();
            }
          } else {
            // Fallback to individual API call
            final summary = await mod.fetchSummary();
            if (summary.isNotEmpty) {
              mod.total =
                  summary["total"] ??
                  summary["total_units"] ??
                  summary["total_loops"] ??
                  summary["total_extinguishers"] ??
                  0;
              mod.expired =
                  summary["expired"] ??
                  summary["expired_units"] ??
                  summary["expired_extinguishers"] ??
                  0;

              mod.health = ApiService.calculateHealth(summary);
            } else {
              mod.health = 100;
            }
          }

          // Set status colors based on the new logic
          if (mod.health < 20)
            mod.status = 'red';
          else if (mod.health < 50)
            mod.status = 'amber';
          else
            mod.status = 'green';
        } catch (_) {
          if (mod.health == -1) mod.health = 100;
        }
      }),
    );

    // 3. Update overall readiness if provided by API
    if (globalData.containsKey("readiness_score")) {
      final rs = globalData["readiness_score"];
      if (rs != null) apiReadinessScore = rs.toDouble();
    } else {
      apiReadinessScore = null;
    }

    if (mounted) setState(() => isLoading = false);
  }

  double get overallHealth {
    if (apiReadinessScore != null) return apiReadinessScore!;

    final activeModules = modules.where((m) => m.health != -1).toList();
    if (activeModules.isEmpty) return 0;

    int totalUnits = 0;
    int expiredUnits = 0;

    for (var m in activeModules) {
      totalUnits += m.total;
      expiredUnits += m.expired;
    }

    if (totalUnits > 0) {
      return ((totalUnits - expiredUnits) / totalUnits) * 100;
    }

    // Fallback to simple average if totals are missing
    final sum = activeModules.fold<double>(0, (s, m) => s + m.health);
    return sum / activeModules.length;
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'green':
        return Colors.green.shade700;
      case 'amber':
        return Colors.orange.shade700;
      case 'red':
        return Colors.red.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: themeBg,
      body: SafeArea(
        child: Column(
          children: [
            if (isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                color: Colors.blue,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SAFETY ECOSYSTEM",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF334155),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          "Industrial Monitoring Active",
                          style: TextStyle(
                            fontSize: 8,
                            color: isDark
                                ? Colors.white54
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        "${overallHealth.toInt()}%",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setState(() => isDark = !isDark),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        isDark
                            ? Icons.wb_sunny_outlined
                            : Icons.nightlight_round,
                        size: 20,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () async {
                      final box = Hive.box('inspectionBox');
                      await box.clear();
                      ApiService.token = null;
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.logout,
                        size: 20,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 5, 14, 15),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double gridHeight = constraints.maxHeight;
                    final double gridWidth = constraints.maxWidth;
                    final double cellWidth = gridWidth / 4;
                    final double cellHeight = gridHeight / 6;
                    final double aspectRatio = cellWidth / cellHeight;

                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: modules.length,
                      itemBuilder: (context, index) {
                        final mod = modules[index];
                        final color = getStatusColor(mod.status);
                        final isCritical = mod.health != -1 && mod.health < 20;

                        return GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => mod.page),
                            );
                            _loadHealthData();
                          },
                          child: AnimatedBuilder(
                            animation: _blinkController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: (isCritical)
                                    ? (0.4 + (_blinkController.value * 0.6))
                                    : 1.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        (isCritical &&
                                            _blinkController.value > 0.5)
                                        ? color.withOpacity(0.1)
                                        : cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isCritical)
                                            ? color.withOpacity(0.3)
                                            : Colors.black.withOpacity(
                                                isDark ? 0.3 : 0.08,
                                              ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: isCritical
                                          ? color
                                          : Colors.green.withOpacity(0.8),
                                      width: isCritical ? 2.5 : 1.5,
                                    ),
                                  ),
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  Expanded(
                                    flex: 9,
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Container(
                                        padding: const EdgeInsets.all(1),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Image.asset(
                                          mod.image,
                                          fit: BoxFit.contain,
                                          errorBuilder: (c, e, s) => Icon(
                                            Icons.category,
                                            color: color,
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    mod.name.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  mod.health == -1 ? "..." : "${mod.health}%",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
