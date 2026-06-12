import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fire_new/local_db.dart';
import 'package:fire_new/sync_service.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'main.dart';
import 'package:fire_new/widgets/health_score_widget.dart';
import 'package:fire_new/global_scanner.dart';
import 'package:fire_new/screens/notifications_page.dart';
import 'package:fire_new/screens/approval_queue_page.dart';
import 'package:fire_new/screens/user_management_page.dart';
import 'package:fire_new/screens/location_management_page.dart';

import 'responsive.dart';
import 'dashboard.dart';
import 'hydrant/dashboard.dart';
import 'hosereel/dashboard.dart' as hose;
import 'sprinklers/sprinkler.dart';
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
import 'services/apiservice.dart';
import 'services/module_api_service.dart';

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

class TransparentImage extends StatefulWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const TransparentImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.errorBuilder,
  });

  @override
  State<TransparentImage> createState() => _TransparentImageState();
}

class _TransparentImageState extends State<TransparentImage> {
  ui.Image? _processedImage;
  bool _isLoading = true;
  bool _hasError = false;
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    _process();
  }

  @override
  void didUpdateWidget(TransparentImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _process();
    }
  }

  Future<void> _process() async {
    if (!mounted) return;
    try {
      final img = await _removeBackgroundCached(widget.assetPath);
      if (mounted) {
        setState(() {
          _processedImage = img;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e, s) {
      debugPrint("Error removing background for ${widget.assetPath}: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _error = e;
          _stackTrace = s;
        });
      }
    }
  }

  static final Map<String, ui.Image> _processedImageCache = {};

  static Future<ui.Image> _removeBackgroundCached(String path) async {
    if (_processedImageCache.containsKey(path)) {
      return _processedImageCache[path]!;
    }

    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final rgbaData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (rgbaData == null) {
      _processedImageCache[path] = image;
      return image;
    }

    final Uint8List pixels = rgbaData.buffer.asUint8List();
    final int len = pixels.length;

    for (int i = 0; i < len; i += 4) {
      final int r = pixels[i];
      final int g = pixels[i + 1];
      final int b = pixels[i + 2];

      // Green screen detection:
      // A bright green pixel: green is high, and much higher than red and blue.
      // Widen the green screen filter slightly to capture compressed edges.
      final bool isGreen = g > 70 && g > r * 1.15 && g > b * 1.15;

      // Advanced White / Off-White / Light-Grey background detection:
      // Key out pixels that are very light (all channels > 195)
      // AND very close to each other in color space (low saturation/variance signifies grey/white background).
      final int maxChannel = r > g ? (r > b ? r : b) : (g > b ? g : b);
      final int minChannel = r < g ? (r < b ? r : b) : (g < b ? g : b);
      final int diff = maxChannel - minChannel;

      final bool isWhite = (r > 195 && g > 195 && b > 195 && diff < 30) || 
                           (r > 230 && g > 230 && b > 230 && diff < 40) ||
                           (r > 240 && g > 240 && b > 240); // Absolute whites

      if (isGreen || isWhite) {
        pixels[i + 3] = 0; // Set Alpha to 0 (make transparent)
      }
    }

    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromPixels(
      pixels,
      image.width,
      image.height,
      ui.PixelFormat.rgba8888,
      (ui.Image img) {
        completer.complete(img);
      },
    );

    final processedImage = await completer.future;
    _processedImageCache[path] = processedImage;
    return processedImage;
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _error ?? Exception("Unknown image error"), _stackTrace);
      }
      return Image.asset(
        widget.assetPath,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }

    if (_isLoading || _processedImage == null) {
      return Image.asset(
        widget.assetPath,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        color: Colors.white.withValues(alpha:0.01),
        colorBlendMode: BlendMode.dstIn,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. Soft Silhouette Glow Layer (Perfect High Contrast outline POP)
        Positioned.fill(
          child: FractionallySizedBox(
            widthFactor: 0.95,
            heightFactor: 0.95,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  isDark ? Colors.white.withValues(alpha:0.28) : Colors.black.withValues(alpha:0.32),
                  BlendMode.srcIn,
                ),
                child: RawImage(
                  image: _processedImage,
                  fit: widget.fit,
                ),
              ),
            ),
          ),
        ),
        // 2. High-Contrast Plain Foreground Image (Slightly Scaled for Maximum Size & Impact!)
        Transform.scale(
          scale: 1.05,
          child: RawImage(
            image: _processedImage,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
          ),
        ),
      ],
    );
  }
}

class _IconsPageState extends State<IconsPage> with TickerProviderStateMixin {
  bool isDark = false;
  bool isLoading = true;
  double? apiReadinessScore;
  late AnimationController _blinkController;
  late AnimationController _syncSpinController;
  int pendingSyncCount = 0;
  bool _isSyncSpinning = false;
  Timer? _pendingRefreshTimer;
  int unreadNotificationsCount = 0;

  late List<ModuleItem> modules;

  Future<void> _loadUnreadNotificationsCount() async {
    try {
      final list = await ApiService.getNotifications();
      final count = list.where((n) => n['read'] != true).length;
      if (mounted) {
        setState(() {
          unreadNotificationsCount = count;
        });
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _syncSpinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _updatePendingCount();
    _loadUnreadNotificationsCount();
    _pendingRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updatePendingCount();
      if (timer.tick % 3 == 0) {
        _loadUnreadNotificationsCount();
      }
    });

    final box = Hive.box('inspectionBox');
    final String role = box
        .get('role', defaultValue: 'user')
        .toString()
        .toLowerCase()
        .trim();
    final rawModules = box.get('modules');
    final bool isAllModules = rawModules == "ALL";
    final List<dynamic> assignedModulesData = (rawModules is List)
        ? rawModules
        : [];

    print("🛠️ DEBUG: Current Role is '$role'");
    print("🛠️ DEBUG: Assigned Modules from API: $rawModules");

    // Extract both IDs and Codes for maximum compatibility
    final Set<String> assignedCodes = {};
    final Set<int> assignedIds = {};

    for (var m in assignedModulesData) {
      if (m is Map) {
        final code = m['code']?.toString().isNotEmpty == true
            ? m['code'].toString()
            : m['module_code']?.toString();
        if (code != null && code.isNotEmpty) {
          assignedCodes.add(LocalDB.normalizeModuleCode(code));
        }
        final idStr = m['id']?.toString().isNotEmpty == true
            ? m['id'].toString()
            : m['module_id']?.toString();
        final id = int.tryParse(idStr ?? '0') ?? 0;
        if (id > 0) assignedIds.add(id);
      } else {
        final s = m.toString();
        final id = int.tryParse(s) ?? 0;
        if (id > 0) {
          assignedIds.add(id);
        } else if (s.isNotEmpty) {
          assignedCodes.add(LocalDB.normalizeModuleCode(s));
        }
      }
    }

    final allModules = _buildAllModulesList();

    // Filter modules based on role and assignments
    bool shouldFilter = true;
    if (role == 'superadmin' || role == 'admin' || isAllModules) {
      if (assignedModulesData.isEmpty || isAllModules) {
        shouldFilter = false;
      }
    }

    if (shouldFilter) {
      print("🔒 Filtering modules for $role based on assignments");
      modules = allModules
          .where(
            (m) =>
                assignedCodes.contains(m.moduleCode) ||
                assignedIds.contains(m.moduleId),
          )
          .toList();
    } else {
      print("✅ Full access granted for role: $role");
      modules = allModules;
    }

    _loadHealthData();
    _fetchDynamicModules();
  }

  @override
  void dispose() {
    _pendingRefreshTimer?.cancel();
    _syncSpinController.dispose();
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

    // 2. Map global data to modules if available (health data only — do NOT change which modules are shown)
    final List<dynamic> globalModules = globalData["modules"] ?? [];

    final List<ModuleItem> modulesNeedingFetch = [];

    // Step A: Resolve immediate local/global maps without network triggers
    for (final mod in modules) {
      try {
        final localSummary = await LocalDB.getModuleMap(
          moduleCode: mod.moduleCode,
          recordType: "summary",
        );

        if (localSummary.isNotEmpty) {
          final upcoming = (localSummary["upcoming"] ?? localSummary["upcoming_units"] ?? 0) as int;
          final active = ((localSummary["active_units"] ?? localSummary["active"] ?? localSummary["active_loops"] ?? 0) as int) + upcoming;
          final service = (localSummary["needs_service"] ?? localSummary["needs_service_units"] ?? 0) as int;
          final inspection = (localSummary["due_inspection"] ?? localSummary["due_inspection_units"] ?? localSummary["due_inspection_loops"] ?? 0) as int;
          final expired = (localSummary["expired"] ?? localSummary["expired_units"] ?? localSummary["expired_loops"] ?? 0) as int;
          int total = (localSummary["total"] ?? localSummary["total_units"] ?? localSummary["total_loops"] ?? localSummary["total_extinguishers"] ?? 0) as int;
          if (total == 0) total = active + service + inspection + expired;

          mod.total = total;
          mod.expired = expired;
          mod.health = ApiService.getHealthScore(localSummary);
          mod.status = ApiService.getHealthStatus(localSummary, mod.health);

          // Add to background staggers to refresh and keep it synced
          modulesNeedingFetch.add(mod);
        } else {
          final globalMod = globalModules.firstWhere(
            (m) =>
                m["module_code"] == mod.moduleCode || m["code"] == mod.moduleCode,
            orElse: () => null,
          );

          if (globalMod != null) {
            final gMod = Map<String, dynamic>.from(globalMod as Map);
            final upcoming = (gMod["upcoming"] ?? gMod["upcoming_units"] ?? 0) as int;
            final active = ((gMod["active_units"] ?? gMod["active"] ?? gMod["active_loops"] ?? 0) as int) + upcoming;
            final service = (gMod["needs_service"] ?? gMod["needs_service_units"] ?? 0) as int;
            final inspection = (gMod["due_inspection"] ?? gMod["due_inspection_units"] ?? gMod["due_inspection_loops"] ?? 0) as int;
            final expired = (gMod["expired"] ?? gMod["expired_units"] ?? gMod["expired_loops"] ?? 0) as int;
            int total = (gMod["total"] ?? gMod["total_units"] ?? gMod["total_loops"] ?? gMod["total_extinguishers"] ?? 0) as int;
            if (total == 0) total = active + service + inspection + expired;

            mod.total = total;
            mod.expired = expired;
            mod.health = ApiService.getHealthScore(gMod);
            mod.status = ApiService.getHealthStatus(gMod, mod.health);

            modulesNeedingFetch.add(mod);
          } else {
            modulesNeedingFetch.add(mod);
          }
        }
      } catch (_) {
        modulesNeedingFetch.add(mod);
      }
    }

    // Step B: Perform staggered fetches for any module NOT covered globally
    // Running in safe concurrent batches of 4 to protect server connection limits
    const int batchSize = 4;
    for (int i = 0; i < modulesNeedingFetch.length; i += batchSize) {
      final int end = (i + batchSize < modulesNeedingFetch.length)
          ? i + batchSize
          : modulesNeedingFetch.length;

      final batch = modulesNeedingFetch.sublist(i, end);

      await Future.wait(
        batch.map((mod) async {
          try {  
            final summary = await mod.fetchSummary();
            if (summary.isNotEmpty) {
              final upcoming = (summary["upcoming"] ?? summary["upcoming_units"] ?? 0) as int;
              final active = ((summary["active_units"] ?? summary["active"] ?? summary["active_loops"] ?? 0) as int) + upcoming;
              final service = (summary["needs_service"] ?? summary["needs_service_units"] ?? 0) as int;
              final inspection = (summary["due_inspection"] ?? summary["due_inspection_units"] ?? summary["due_inspection_loops"] ?? 0) as int;
              final expired = (summary["expired"] ?? summary["expired_units"] ?? summary["expired_loops"] ?? 0) as int;
              int total = (summary["total"] ?? summary["total_units"] ?? summary["total_loops"] ?? summary["total_extinguishers"] ?? 0) as int;
              if (total == 0) total = active + service + inspection + expired;

              mod.total = total;
              mod.expired = expired;
              mod.health = ApiService.getHealthScore(summary);
              mod.status = ApiService.getHealthStatus(summary, mod.health);
            } else {
              mod.health = 100;
              _assignModuleStatus(mod);
            }
          } catch (_) {
            if (mod.health == -1) mod.health = 100;
            _assignModuleStatus(mod);
          }
        }),
      );
    }

    // 3. Update overall readiness if provided by API
    if (globalData.containsKey("readiness_score")) {
      final rs = globalData["readiness_score"];
      if (rs != null) apiReadinessScore = rs.toDouble();
    } else {
      apiReadinessScore = null;
    }

    await _loadUnreadNotificationsCount();

    if (mounted) setState(() => isLoading = false);
  }

  void _assignModuleStatus(ModuleItem mod) {
    if (mod.health >= 90) {
      mod.status = 'green';
    } else if (mod.health >= 80) {
      mod.status = 'amber';
    } else {
      mod.status = 'red';
    }
  }

  Future<void> _fetchDynamicModules() async {
    final box = Hive.box('inspectionBox');
    final String role = box.get('role', defaultValue: 'user').toString().toLowerCase().trim();
    final String userId = box.get('userId', defaultValue: '').toString();
    
    if (userId.isEmpty) {
      return;
    }
    
    try {
      final userProfile = await ApiService.getAdminUser(userId);
      if (userProfile != null && mounted) {
        final rawModules = userProfile["modules"];
        
        // Save to Hive cache
        await box.put('modules', rawModules);
        
        final Set<String> assignedCodes = {};
        final Set<int> assignedIds = {};
        
        final bool isAllModules = rawModules == "ALL";
        final List<dynamic> updatedModules = (rawModules is List)
            ? rawModules
            : [];
            
        for (var m in updatedModules) {
          if (m is Map) {
            final code = m['code']?.toString().isNotEmpty == true
                ? m['code'].toString()
                : m['module_code']?.toString();
            if (code != null && code.isNotEmpty) {
              assignedCodes.add(LocalDB.normalizeModuleCode(code));
            }
            final idStr = m['id']?.toString().isNotEmpty == true
                ? m['id'].toString()
                : m['module_id']?.toString();
            final id = int.tryParse(idStr ?? '0') ?? 0;
            if (id > 0) assignedIds.add(id);
          } else {
            final s = m.toString();
            final id = int.tryParse(s) ?? 0;
            if (id > 0) {
              assignedIds.add(id);
            } else if (s.isNotEmpty) {
              assignedCodes.add(LocalDB.normalizeModuleCode(s));
            }
          }
        }
        
        final allModules = _buildAllModulesList();
        
        bool shouldFilter = true;
        if (role == 'superadmin' || role == 'admin' || isAllModules) {
          if (updatedModules.isEmpty || isAllModules) {
            shouldFilter = false;
          }
        }
        
        setState(() {
          if (shouldFilter) {
            modules = allModules.where((m) =>
              assignedCodes.contains(m.moduleCode) ||
              assignedIds.contains(m.moduleId)
            ).toList();
          } else {
            modules = allModules;
          }
        });
        
        // Reload health scores for newly fetched modules
        _loadHealthData();
      }
    } catch (e) {
      print("Error fetching dynamic modules on load: $e");
    }
  }

  List<ModuleItem> _buildAllModulesList() {
    return [
      ModuleItem(
        name: 'Extinguishers',
        image: 'assets/extinguisher.webp',
        moduleCode: 'fire_extinguisher',
        moduleId: 30,
        page: const DashboardPage(),
        fetchSummary: () => ModuleApiService.extinguisher.getSummary(),
      ),
      ModuleItem(
        name: 'Hose Reels',
        image: 'assets/hosereel.webp',
        moduleCode: 'hose_reel',
        moduleId: 33,
        page: const hose.Dashboard(),
        fetchSummary: () => ModuleApiService.hoseReel.getSummary(),
      ),
      ModuleItem(
        name: 'Sprinklers',
        image: 'assets/sprinkler.webp',
        moduleCode: 'sprinkler',
        moduleId: 31,
        page: const SprinklerPage(),
        fetchSummary: () => ModuleApiService.sprinkler.getSummary(),
      ),
      ModuleItem(
        name: 'Hydrants',
        image: 'assets/firehydrant.webp',
        moduleCode: 'hydrant',
        moduleId: 34,
        page: const HydrantDashboardPage(),
        fetchSummary: () => ModuleApiService.hydrant.getSummary(),
      ),
      ModuleItem(
        name: 'Alarm Panels',
        image: 'assets/alarm_panel.webp',
        moduleCode: 'fire_alarm',
        moduleId: 35,
        page: const AlarmPanelDashboard(),
        fetchSummary: () => ModuleApiService.alarmPanel.getSummary(),
      ),
      ModuleItem(
        name: 'Smoke Det.',
        image: 'assets/smoke_detector.webp',
        moduleCode: 'smoke_detector',
        moduleId: 36,
        page: const SmokeDetectorDashboard(),
        fetchSummary: () => ModuleApiService.smokeDetector.getSummary(),
      ),
      ModuleItem(
        name: 'Fire Trolley',
        image: 'assets/fire_trolley.webp',
        moduleCode: 'fire_trolley',
        moduleId: 55,
        page: const FireTrolleyDashboard(),
        fetchSummary: () => ModuleApiService.fireTrolley.getSummary(),
      ),
      ModuleItem(
        name: 'Exits',
        image: 'assets/emergency_exit.webp',
        moduleCode: 'exit_sign',
        moduleId: 39,
        page: const EmergencyExitsDashboard(),
        fetchSummary: () => ModuleApiService.emergencyExit.getSummary(),
      ),
      ModuleItem(
        name: 'Ambulance',
        image: 'assets/ambulance.webp',
        moduleCode: 'ambulance',
        moduleId: 58,
        page: const AmbulanceDashboard(),
        fetchSummary: () => ModuleApiService.ambulance.getSummary(),
      ),
      ModuleItem(
        name: 'Lighting',
        image: 'assets/emergency_lighting.webp',
        moduleCode: 'emergency_light',
        moduleId: 38,
        page: const EmergencyLightingDashboard(),
        fetchSummary: () => ModuleApiService.emergencyLight.getSummary(),
      ),
      ModuleItem(
        name: 'PA System',
        image: 'assets/pa_system.webp',
        moduleCode: 'pa_system',
        moduleId: 44,
        page: const PASystemDashboard(),
        fetchSummary: () => ModuleApiService.paSystem.getSummary(),
      ),
      ModuleItem(
        name: 'Wind Sock',
        image: 'assets/wind_sock.webp',
        moduleCode: 'wind_sock',
        moduleId: 56,
        page: const WindSockDashboard(),
        fetchSummary: () => ModuleApiService.windSock.getSummary(),
      ),
      ModuleItem(
        name: 'SCBA Units',
        image: 'assets/scba_unit.webp',
        moduleCode: 'scba_unit',
        moduleId: 57,
        page: const SCBAUnitsDashboard(),
        fetchSummary: () => ModuleApiService.scbaUnit.getSummary(),
      ),
      ModuleItem(
        name: 'First Aid',
        image: 'assets/first_aid.webp',
        moduleCode: 'first_aid_kit',
        moduleId: 45,
        page: const FirstAidDashboard(),
        fetchSummary: () => ModuleApiService.firstAid.getSummary(),
      ),
      ModuleItem(
        name: 'Shower',
        image: 'assets/emergency_shower.webp',
        moduleCode: 'safety_shower',
        moduleId: 47,
        page: const EmergencyShowerDashboard(),
        fetchSummary: () => ModuleApiService.safetyShower.getSummary(),
      ),
      ModuleItem(
        name: 'Eye Wash',
        image: 'assets/eye_wash.webp',
        moduleCode: 'eyewash_station',
        moduleId: 46,
        page: const EyeWashDashboard(),
        fetchSummary: () => ModuleApiService.eyeWash.getSummary(),
      ),
      ModuleItem(
        name: 'Spill Kits',
        image: 'assets/spill_kits.webp',
        moduleCode: 'spill_kit',
        moduleId: 48,
        page: const SpillKitsDashboard(),
        fetchSummary: () => ModuleApiService.spillKit.getSummary(),
      ),
      ModuleItem(
        name: 'PPE Cabs',
        image: 'assets/ppe_cabinets.webp',
        moduleCode: 'ppe_station',
        moduleId: 49,
        page: const PPECabinetsDashboard(),
        fetchSummary: () => ModuleApiService.ppeCabinet.getSummary(),
      ),
      ModuleItem(
        name: 'CO2 System',
        image: 'assets/co2_system.webp',
        moduleCode: 'suppression_system',
        moduleId: 42,
        page: const CO2SystemDashboard(),
        fetchSummary: () => ModuleApiService.co2System.getSummary(),
      ),
      ModuleItem(
        name: 'Signage',
        image: 'assets/signage.webp',
        moduleCode: 'signage',
        moduleId: 62,
        page: const SignageDashboard(),
        fetchSummary: () => ModuleApiService.signage.getSummary(),
      ),
      ModuleItem(
        name: 'Comm.',
        image: 'assets/emergency_comm.webp',
        moduleCode: 'emergency_comm',
        moduleId: 61,
        page: const EmergencyCommDashboard(),
        fetchSummary: () => ModuleApiService.emergencyComm.getSummary(),
      ),
      ModuleItem(
        name: 'Blankets',
        image: 'assets/fire_blankets.webp',
        moduleCode: 'fire_blanket',
        moduleId: 41,
        page: const FireBlanketsDashboard(),
        fetchSummary: () => ModuleApiService.fireBlanket.getSummary(),
      ),
      ModuleItem(
        name: 'Muster Pt.',
        image: 'assets/muster_points.webp',
        moduleCode: 'muster_point',
        moduleId: 59,
        page: const MusterPointsDashboard(),
        fetchSummary: () => ModuleApiService.musterPoint.getSummary(),
      ),
      ModuleItem(
        name: 'Heat Det.',
        image: 'assets/heat_detector.webp',
        moduleCode: 'heat_detector',
        moduleId: 37,
        page: const HeatDetectorDashboard(),
        fetchSummary: () => ModuleApiService.heatDetector.getSummary(),
      ),
      ModuleItem(
        name: 'CO Detector',
        image: 'assets/co_detector.webp',
        moduleCode: 'co_detector',
        moduleId: 40,
        page: const CODetectorDashboard(),
        fetchSummary: () => ModuleApiService.coDetector.getSummary(),
      ),
      ModuleItem(
        name: 'Fire Door',
        image: 'assets/fire_door.webp',
        moduleCode: 'fire_door',
        moduleId: 43,
        page: const FireDoorDashboard(),
        fetchSummary: () => ModuleApiService.fireDoor.getSummary(),
      ),
    ];
  }

  Future<void> _updatePendingCount() async {
    if (kIsWeb) return;
    try {
      final legacy = await LocalDB.getPending();
      final modules = await LocalDB.getPendingModuleInspections();
      final int total = legacy.length + modules.length;
      if (mounted && pendingSyncCount != total) {
        setState(() {
          pendingSyncCount = total;
        });
      }
    } catch (e) {
      debugPrint("Sync count refresh error: $e");
    }
  }

  Future<void> _triggerManualSync() async {
    if (_isSyncSpinning) return;
    setState(() => _isSyncSpinning = true);
    _syncSpinController.repeat();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🔄 Syncing pending records to Cloud...")),
    );

    try {
      await SyncService.syncData();
    } catch (e) {
      debugPrint("Manual Sync failure: $e");
    }

    await _updatePendingCount();

    if (mounted) {
      _syncSpinController.stop();
      setState(() => _isSyncSpinning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: pendingSyncCount == 0 ? Colors.green : Colors.orange,
          content: Text(
            pendingSyncCount == 0
                ? "✅ Sync Complete! All records online!"
                : "⚠️ Partial Sync! $pendingSyncCount still secured offline.",
          ),
        ),
      );
    }
  }

  double get overallHealth {
    final activeModules = modules.where((m) => m.health != -1).toList();
    if (activeModules.isEmpty) return 0;

    // Compute overallHealth as a simple average of active modules' health scores
    final sum = activeModules.fold<double>(0, (s, m) => s + m.health);
    return sum / activeModules.length;
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'green':
        return const Color(0xFF1E8E3E); // Vibrant Emerald Green (Aligned with Dashboard)
      case 'amber':
        return const Color(0xFFFF8F00); // Vibrant Warm Amber (Aligned with Dashboard)
      case 'red':
        return const Color(0xFFD50000); // Vibrant Hot Red (Aligned with Dashboard)
      default:
        return const Color(0xFF64748B); // Slate Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: themeBg,
      body: SafeArea(
        child: Stack(
          children: [
            IgnorePointer(
              child: Center(
                child: Opacity(
                  opacity: isDark ? 0.03 : 0.07,
                  child: Image.asset(
                    'assets/eltrive_logo.webp',
                    width: 260,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            ListView(
              physics: const BouncingScrollPhysics(),
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
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha:0.08),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/eltrive_logo.webp',
                                  height: 32,
                                  width: 32,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                "ELTRIVE SAFETY",
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF334155),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Industrial Monitoring Active",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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
                  const SizedBox(width: 12),
                  Flexible(
                    flex: 0,
                    child: HealthScoreWidget(health: overallHealth.round()),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(
                      Icons.qr_code_scanner_rounded,
                      color: isDark ? Colors.white70 : Colors.black87,
                      size: 28,
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GlobalScannerPage()),
                      );
                      _updatePendingCount();
                      _loadHealthData();
                    },
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.notifications_rounded,
                          color: isDark ? Colors.white70 : Colors.black87,
                          size: 28,
                        ),
                        if (unreadNotificationsCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                              child: Center(
                                child: Text(
                                  "$unreadNotificationsCount",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => NotificationsPage(isDark: isDark)),
                      );
                      _loadUnreadNotificationsCount();
                    },
                  ),
                  const SizedBox(width: 12),
                  PopupMenuButton<String>(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.menu_rounded,
                          color: isDark ? Colors.white70 : Colors.black87,
                          size: 28,
                        ),
                        if (pendingSyncCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                              child: Center(
                                child: Text(
                                  "$pendingSyncCount",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: isDark ? const Color(0xFF334155) : Colors.white,
                    onSelected: (value) async {
                      final box = Hive.box('inspectionBox');

                      if (value == 'light') {
                        setState(() => isDark = false);
                      } else if (value == 'dark') {
                        setState(() => isDark = true);
                      } else if (value == 'sync') {
                        _triggerManualSync();
                      } else if (value == 'approval_queue') {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ApprovalQueuePage(isDark: isDark)),
                        );
                        _loadHealthData();
                      } else if (value == 'locations') {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LocationManagementPage(isDark: isDark)),
                        );
                      } else if (value == 'user_directory') {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => UserManagementPage(isDark: isDark)),
                        );
                        _loadHealthData();
                      } else if (value == 'logout') {
                        await box.clear();
                        ApiService.token = null;
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                            (route) => false,
                          );
                        }
                      } else if (value == 'about') {
                        showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            title: Text(
                              "Eltrive Safety Active Matrix",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: 80,
                                  width: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? Colors.white24 : Colors.black12,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha:0.12),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/eltrive_logo.webp',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  "Version 3.2.0 - Active Compliance Protocol",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Designed to monitor, inspect, and synchronize the safety infrastructure of Eltrive plants.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c),
                                child: const Text("CLOSE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) {
                      final box = Hive.box('inspectionBox');
                      final String role = box.get('role', defaultValue: 'user').toString().toLowerCase().trim();
                      return [
                        PopupMenuItem(
                          value: 'light',
                          child: Row(
                            children: [
                              Icon(Icons.wb_sunny_rounded, color: Colors.amber.shade700, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                "Light Theme",
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!isDark) ...[
                                const Spacer(),
                                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                              ],
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'dark',
                          child: Row(
                            children: [
                              Icon(Icons.nightlight_round, color: Colors.indigo.shade300, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                "Dark Theme",
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isDark) ...[
                                const Spacer(),
                                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                              ],
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'sync',
                          child: Row(
                            children: [
                              const Icon(Icons.sync_rounded, color: Colors.blue, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                "Sync All Modules",
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'approval_queue',
                          child: Row(
                            children: [
                              const Icon(Icons.rule_folder_rounded, color: Colors.purple, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                role == 'supervisor' || role == 'admin' || role == 'superadmin'
                                    ? "Approval Queue"
                                    : "My Requests",
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (role == 'admin' || role == 'superadmin')
                          PopupMenuItem(
                            value: 'locations',
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_rounded, color: Colors.red, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  "Locations",
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (role == 'admin' || role == 'superadmin')
                          PopupMenuItem(
                            value: 'user_directory',
                            child: Row(
                              children: [
                                const Icon(Icons.people_alt_rounded, color: Colors.orange, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  "User Directory",
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'about',
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, color: Colors.teal, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                "About App",
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'logout',
                          child: const Row(
                            children: [
                              Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                "Logout",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 5, 14, 15),
              child: LayoutBuilder(
                builder: (context, constraints) {
                      final bool isTab = Responsive.isTablet(context);
                      final bool isDesk = Responsive.isDesktop(context);
                      final int crossAxisCount = isDesk ? 6 : (isTab ? 4 : 3);

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: isDesk
                              ? 1.0
                              : (isTab ? 0.85 : 0.8),
                        ),
                        itemCount: modules.length,
                        itemBuilder: (context, index) {
                          final mod = modules[index];
                          final color = getStatusColor(mod.status);

                          return GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => mod.page),
                              );
                              _updatePendingCount();
                              _loadHealthData();
                            },
                            child: AnimatedBuilder(
                              animation: _blinkController,
                              builder: (context, child) {
                                // Define borders, colors, and shadows based on status for premium glowing blinking effects
                                final double pulse = _blinkController.value;
                                
                                Color animatedBorderColor;
                                double borderWidth;
                                Color animatedBgColor;
                                List<BoxShadow> animatedShadows;

                                if (mod.health == -1) {
                                  // Loading state
                                  animatedBorderColor = isDark 
                                      ? Colors.white.withValues(alpha:0.15) 
                                      : Colors.black.withValues(alpha:0.08);
                                  borderWidth = 1.5;
                                  animatedBgColor = cardBg;
                                  animatedShadows = [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha:isDark ? 0.25 : 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ];
                                } else {
                                  // Active states: Red, Amber, Green
                                  animatedBorderColor = color.withValues(alpha:0.40 + (pulse * 0.60));
                                  
                                  if (mod.status == 'red') {
                                    borderWidth = 2.2 + (pulse * 1.3);
                                    animatedBgColor = Color.lerp(
                                      cardBg,
                                      color.withValues(alpha:isDark ? 0.35 : 0.22),
                                      pulse,
                                    )!;
                                    animatedShadows = [
                                      BoxShadow(
                                        color: color.withValues(alpha:0.20 + (pulse * 0.30)),
                                        blurRadius: 8.0 + (pulse * 8.0),
                                        offset: const Offset(0, 4),
                                      )
                                    ];
                                  } else if (mod.status == 'amber') {
                                    borderWidth = 1.8 + (pulse * 0.8);
                                    animatedBgColor = Color.lerp(
                                      cardBg,
                                      color.withValues(alpha:isDark ? 0.28 : 0.17),
                                      pulse,
                                    )!;
                                    animatedShadows = [
                                      BoxShadow(
                                        color: color.withValues(alpha:0.15 + (pulse * 0.20)),
                                        blurRadius: 6.0 + (pulse * 6.0),
                                        offset: const Offset(0, 4),
                                      )
                                    ];
                                  } else {
                                    // Green (Healthy)
                                    borderWidth = 1.5 + (pulse * 0.4);
                                    animatedBgColor = Color.lerp(
                                      cardBg,
                                      color.withValues(alpha:isDark ? 0.22 : 0.13),
                                      pulse,
                                    )!;
                                    animatedShadows = [
                                      BoxShadow(
                                        color: color.withValues(alpha:0.10 + (pulse * 0.12)),
                                        blurRadius: 5.0 + (pulse * 4.0),
                                        offset: const Offset(0, 4),
                                      )
                                    ];
                                  }
                                }

                                return Container(
                                  decoration: BoxDecoration(
                                    color: animatedBgColor,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: animatedShadows,
                                    border: Border.all(
                                      color: animatedBorderColor,
                                      width: borderWidth,
                                    ),
                                  ),
                                  child: child,
                                );
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 9,
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Hero(
                                        tag: "hero_image_${mod.image}",
                                        child: TransparentImage(
                                          assetPath: mod.image,
                                          fit: BoxFit.contain,
                                          errorBuilder: (c, e, s) => Icon(
                                            Icons.category,
                                            color: color,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        mod.name.toUpperCase(),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10.0,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      mod.health == -1 ? "..." : "${mod.health}%",
                                      style: TextStyle(
                                        fontSize: 10,
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
