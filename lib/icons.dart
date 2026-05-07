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
  int health;
  String status;
  int total;
  int expired;

  ModuleItem({
    required this.name,
    required this.image,
    required this.moduleCode,
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

  late final List<ModuleItem> modules;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    modules = [
      ModuleItem(
        name: 'Extinguishers',
        image: 'assets/extinguisher.png',
        moduleCode: 'fire_extinguisher',
        page: const DashboardPage(),
        fetchSummary: () => ApiService.getSummary(),
      ),
      ModuleItem(
        name: 'Hose Reels',
        image: 'assets/hosereel.png',
        moduleCode: 'hose_reel',
        page: const hose.Dashboard(),
        fetchSummary: () => HoseReelApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Sprinklers',
        image: 'assets/sprinkler.png',
        moduleCode: 'sprinkler',
        page: const SprinklerPage(),
        fetchSummary: () => SprinklerApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Hydrants',
        image: 'assets/firehydrant.png',
        moduleCode: 'hydrant',
        page: const HydrantDashboardPage(),
        fetchSummary: () => HydrantApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Alarm Panels',
        image: 'assets/alarm_panel.png',
        moduleCode: 'fire_alarm',
        page: const AlarmPanelDashboard(),
        fetchSummary: () => AlarmPanelApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Smoke Det.',
        image: 'assets/smoke_detector.png',
        moduleCode: 'smoke_detector',
        page: const SmokeDetectorDashboard(),
        fetchSummary: () => SmokeDetectorApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Fire Trolley',
        image: 'assets/fire_trolley.png',
        moduleCode: 'fpca',
        page: const FireTrolleyDashboard(),
        fetchSummary: () => FireTrolleyApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Exits',
        image: 'assets/emergency_exit.png',
        moduleCode: 'exit_sign',
        page: const EmergencyExitsDashboard(),
        fetchSummary: () => EmergencyExitsApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Lighting',
        image: 'assets/emergency_lighting.png',
        moduleCode: 'emergency_light',
        page: const EmergencyLightingDashboard(),
        fetchSummary: () => EmergencyLightingApiService().getSummary(),
      ),
      ModuleItem(
        name: 'PA System',
        image: 'assets/pa_system.png',
        moduleCode: 'pa_system',
        page: const PASystemDashboard(),
        fetchSummary: () => PASystemApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Wind Sock',
        image: 'assets/wind_sock.png',
        moduleCode: 'wind_sock',
        page: const WindSockDashboard(),
        fetchSummary: () => WindSockApiService().getSummary(),
      ),
      ModuleItem(
        name: 'SCBA Units',
        image: 'assets/scba_unit.png',
        moduleCode: 'scba_unit',
        page: const SCBAUnitsDashboard(),
        fetchSummary: () => SCBAUnitsApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Ambulance',
        image: 'assets/ambulance.png',
        moduleCode: 'ambulance',
        page: const AmbulanceDashboard(),
        fetchSummary: () => AmbulanceApiService().getSummary(),
      ),
      ModuleItem(
        name: 'First Aid',
        image: 'assets/first_aid.png',
        moduleCode: 'first_aid_kit',
        page: const FirstAidDashboard(),
        fetchSummary: () => FirstAidApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Shower',
        image: 'assets/emergency_shower.png',
        moduleCode: 'safety_shower',
        page: const EmergencyShowerDashboard(),
        fetchSummary: () => EmergencyShowerApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Eye Wash',
        image: 'assets/eye_wash.png',
        moduleCode: 'eyewash_station',
        page: const EyeWashDashboard(),
        fetchSummary: () => EyeWashApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Spill Kits',
        image: 'assets/spill_kits.png',
        moduleCode: 'spill_kit',
        page: const SpillKitsDashboard(),
        fetchSummary: () => SpillKitsApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Chem Shower',
        image: 'assets/chemical_shower.png',
        moduleCode: 'chemical_shower',
        page: const ChemicalShowerDashboard(),
        fetchSummary: () => ChemicalShowerApiService().getSummary(),
      ),
      ModuleItem(
        name: 'PPE Cabs',
        image: 'assets/ppe_cabinets.png',
        moduleCode: 'ppe_station',
        page: const PPECabinetsDashboard(),
        fetchSummary: () => PPECabinetsApiService().getSummary(),
      ),
      ModuleItem(
        name: 'CO2 System',
        image: 'assets/co2_system.png',
        moduleCode: 'suppression_system',
        page: const CO2SystemDashboard(),
        fetchSummary: () => CO2SystemApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Signage',
        image: 'assets/signage.png',
        moduleCode: 'signage',
        page: const SignageDashboard(),
        fetchSummary: () => SignageApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Comm.',
        image: 'assets/emergency_comm.png',
        moduleCode: 'emergency_comm',
        page: const EmergencyCommDashboard(),
        fetchSummary: () => EmergencyCommApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Blankets',
        image: 'assets/fire_blankets.png',
        moduleCode: 'fire_blanket',
        page: const FireBlanketsDashboard(),
        fetchSummary: () => FireBlanketsApiService().getSummary(),
      ),
      ModuleItem(
        name: 'Muster Pt.',
        image: 'assets/muster_points.png',
        moduleCode: 'muster_points',
        page: const MusterPointsDashboard(),
        fetchSummary: () => MusterPointsApiService().getSummary(),
      ),
    ];
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

              if (mod.total > 0) {
                mod.health = ApiService.calculateHealth(summary);
              } else {
                final hs = summary["health_score"] ?? summary["health"] ?? 100;
                mod.health = hs.toInt();
              }
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
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => isDark = !isDark),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        isDark
                            ? Icons.wb_sunny_outlined
                            : Icons.nightlight_round,
                        size: 16,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final box = Hive.box('inspectionBox');
                      await box.delete('token');
                      ApiService.token = null;
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                        ],
                      ),
                      child: const Icon(Icons.logout, size: 16, color: Colors.red),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, color: Colors.red, size: 16),
                        const SizedBox(width: 6),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "HEALTH",
                              style: TextStyle(
                                fontSize: 6,
                                fontWeight: FontWeight.w900,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              isLoading && overallHealth == 0
                                  ? "..."
                                  : "${overallHealth.toInt()}%",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            if (!isLoading)
                              Text(
                                "${modules.fold<int>(0, (s, m) => s + (m.total - m.expired))}/${modules.fold<int>(0, (s, m) => s + m.total)} READY",
                                style: const TextStyle(
                                  fontSize: 5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.sync,
                      size: 18,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                    onPressed: _loadHealthData,
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
                      physics: const NeverScrollableScrollPhysics(),
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
                                      color: color.withOpacity(
                                        isCritical ? 0.8 : 0.2,
                                      ),
                                      width: isCritical ? 2 : 1,
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
                                  flex: 6,
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: Colors.green,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Image.asset(
                                        mod.image,
                                        fit: BoxFit.contain,
                                        errorBuilder: (c, e, s) => Icon(
                                          Icons.category,
                                          color: color,
                                          size: 20,
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    mod.health == -1 ? "..." : "${mod.health}%",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: color,
                                    ),
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
