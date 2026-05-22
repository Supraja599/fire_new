import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fire_new/local_db.dart';
import 'package:fire_new/services/apiservice.dart';
import 'dart:ui';

// Import all 26 inspection pages
import 'package:fire_new/inspection.dart';
import 'package:fire_new/hosereel/inspection.dart';
import 'package:fire_new/sprinklers/inspection.dart';
import 'package:fire_new/hydrant/inspection.dart';
import 'package:fire_new/alarm_panel/inspection.dart';
import 'package:fire_new/smoke_detector/inspection.dart';
import 'package:fire_new/fire_trolley/inspection.dart';
import 'package:fire_new/emergency_exits/inspection.dart';
import 'package:fire_new/emergency_lighting/inspection.dart';
import 'package:fire_new/pa_system/inspection.dart';
import 'package:fire_new/wind_sock/inspection.dart';
import 'package:fire_new/scba_units/inspection.dart';
import 'package:fire_new/ambulance/inspection.dart';
import 'package:fire_new/first_aid/inspection.dart';
import 'package:fire_new/emergency_shower/inspection.dart';
import 'package:fire_new/eye_wash/inspection.dart';
import 'package:fire_new/spill_kits/inspection.dart';
import 'package:fire_new/ppe_cabinets/inspection.dart';
import 'package:fire_new/co2_system/inspection.dart';
import 'package:fire_new/signage/inspection.dart';
import 'package:fire_new/emergency_comm/inspection.dart';
import 'package:fire_new/fire_blankets/inspection.dart';
import 'package:fire_new/muster_points/inspection.dart';
import 'package:fire_new/heat_detector/inspection.dart';
import 'package:fire_new/co_detector/inspection.dart';
import 'package:fire_new/fire_door/inspection.dart';

class GlobalScannerPage extends StatefulWidget {
  const GlobalScannerPage({super.key});

  @override
  State<GlobalScannerPage> createState() => _GlobalScannerPageState();
}

class _GlobalScannerPageState extends State<GlobalScannerPage> with SingleTickerProviderStateMixin {
  final TextEditingController idController = TextEditingController();
  final MobileScannerController scannerController = MobileScannerController();
  
  late AnimationController _laserController;
  bool isLoading = false;
  String? errorMessage;
  bool isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    idController.dispose();
    scannerController.dispose();
    super.dispose();
  }

  // Universal lookup logic
  Future<void> _handleSearch(String input) async {
    final searchId = input.trim();
    if (searchId.isEmpty) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // 1. Check local SQLite DB first (legacy extinguishers & other module equipment)
      final localMatch = await LocalDB.findEquipmentModuleAndData(searchId);
      if (localMatch != null) {
        final moduleCode = localMatch['module_code']?.toString();
        if (moduleCode != null) {
          _navigateToModule(moduleCode, searchId);
          return;
        }
      }

      // 2. Fetch from cloud API globally
      final apiMatch = await ApiService.searchAny(searchId);
      if (apiMatch != null) {
        final moduleCode = apiMatch['module_code']?.toString() ?? 'fire_extinguisher';
        // Cache locally for offline availability next time
        if (moduleCode == 'fire_extinguisher') {
          await LocalDB.insert(searchId, apiMatch);
        } else {
          await LocalDB.saveSingleModuleRecord(
            moduleCode: moduleCode,
            recordType: 'equipment',
            item: apiMatch,
          );
        }
        _navigateToModule(moduleCode, searchId);
        return;
      }

      // 3. Not found anywhere
      setState(() {
        isLoading = false;
        errorMessage = "Equipment not found. Please verify the ID or try again.";
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error during lookup: $e";
      });
    }
  }

  void _navigateToModule(String moduleCode, String equipmentId) {
    Widget page;
    switch (moduleCode) {
      case 'fire_extinguisher':
        page = InspectionPage(preScannedId: equipmentId);
        break;
      case 'hose_reel':
        page = HoseReelInspectionPage(preScannedId: equipmentId);
        break;
      case 'sprinkler':
        page = SprinklerInspectionPage(preScannedId: equipmentId);
        break;
      case 'hydrant':
        page = HydrantInspectionPage(preScannedId: equipmentId);
        break;
      case 'fire_alarm':
        page = AlarmPanelInspectionPage(preScannedId: equipmentId);
        break;
      case 'smoke_detector':
        page = SmokeDetectorInspectionPage(preScannedId: equipmentId);
        break;
      case 'fire_trolley':
        page = FireTrolleyInspectionPage(preScannedId: equipmentId);
        break;
      case 'exit_sign':
        page = EmergencyExitsInspectionPage(preScannedId: equipmentId);
        break;
      case 'emergency_light':
        page = EmergencyLightingInspectionPage(preScannedId: equipmentId);
        break;
      case 'pa_system':
        page = PASystemInspectionPage(preScannedId: equipmentId);
        break;
      case 'wind_sock':
        page = WindSockInspectionPage(preScannedId: equipmentId);
        break;
      case 'scba_unit':
        page = SCBAUnitsInspectionPage(preScannedId: equipmentId);
        break;
      case 'ambulance':
        page = AmbulanceInspectionPage(preScannedId: equipmentId);
        break;
      case 'first_aid_kit':
        page = FirstAidInspectionPage(preScannedId: equipmentId);
        break;
      case 'safety_shower':
        page = EmergencyShowerInspectionPage(preScannedId: equipmentId);
        break;
      case 'eyewash_station':
        page = EyeWashInspectionPage(preScannedId: equipmentId);
        break;
      case 'spill_kit':
        page = SpillKitsInspectionPage(preScannedId: equipmentId);
        break;
      case 'ppe_station':
        page = PPECabinetsInspectionPage(preScannedId: equipmentId);
        break;
      case 'suppression_system':
        page = CO2SystemInspectionPage(preScannedId: equipmentId);
        break;
      case 'signage':
        page = SignageInspectionPage(preScannedId: equipmentId);
        break;
      case 'emergency_comm':
        page = EmergencyCommInspectionPage(preScannedId: equipmentId);
        break;
      case 'fire_blanket':
        page = FireBlanketsInspectionPage(preScannedId: equipmentId);
        break;
      case 'muster_point':
        page = MusterPointsInspectionPage(preScannedId: equipmentId);
        break;
      case 'heat_detector':
        page = HeatDetectorInspectionPage(preScannedId: equipmentId);
        break;
      case 'co_detector':
        page = CODetectorInspectionPage(preScannedId: equipmentId);
        break;
      case 'fire_door':
        page = FireDoorInspectionPage(preScannedId: equipmentId);
        break;
      default:
        setState(() {
          isLoading = false;
          errorMessage = "Unknown module code: $moduleCode";
        });
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;
    
    // Rich dark slate backgrounds for high contrast scanner design
    final bgDark = const Color(0xFF0B0F19);
    final cardBg = const Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: bgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Universal Scanner",
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: isFlashOn ? Colors.amber : Colors.white,
            ),
            onPressed: () {
              scannerController.toggleTorch();
              setState(() {
                isFlashOn = !isFlashOn;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Mobile Scanner View (takes full screen background)
          Positioned.fill(
            child: MobileScanner(
              controller: scannerController,
              onDetect: (capture) {
                if (capture.barcodes.isNotEmpty && !isLoading) {
                  final code = capture.barcodes.first.rawValue;
                  if (code != null && code.trim().isNotEmpty) {
                    _handleSearch(code);
                  }
                }
              },
            ),
          ),

          // 2. Glassmorphic Scanner Viewfinder and Laser Overlays
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.55),
              child: SafeArea(
                child: Column(
                  children: [
                    const Spacer(),
                    
                    // Center scanner target box
                    Center(
                      child: Container(
                        width: 270,
                        height: 270,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white24, width: 2),
                        ),
                        child: Stack(
                          children: [
                            // Glowing border corner accents
                            Positioned(
                              top: -2, left: -2,
                              child: _buildCornerAccent(top: true, left: true),
                            ),
                            Positioned(
                              top: -2, right: -2,
                              child: _buildCornerAccent(top: true, left: false),
                            ),
                            Positioned(
                              bottom: -2, left: -2,
                              child: _buildCornerAccent(top: false, left: true),
                            ),
                            Positioned(
                              bottom: -2, right: -2,
                              child: _buildCornerAccent(top: false, left: false),
                            ),

                            // Laser scanning line animation
                            AnimatedBuilder(
                              animation: _laserController,
                              builder: (context, child) {
                                return Positioned(
                                  top: _laserController.value * 260 + 5,
                                  left: 10,
                                  right: 10,
                                  child: Container(
                                    height: 3.5,
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.red.withOpacity(0.8),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    const Text(
                      "Scan any equipment barcode / QR code to inspect",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),

                    // 3. Bottom Card for Manual Entering & Error messages
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      decoration: BoxDecoration(
                        color: cardBg.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      errorMessage!,
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 15),
                          ],
                          
                          const Text(
                            "OR SEARCH MANUALLY",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: idController,
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: "Enter SOS Code or ID",
                                    hintStyle: const TextStyle(color: Colors.white38),
                                    filled: true,
                                    fillColor: Colors.black26,
                                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white60),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                                    ),
                                  ),
                                  onSubmitted: (val) => _handleSearch(val),
                                ),
                              ),
                              const SizedBox(width: 10),
                              InkWell(
                                onTap: () => _handleSearch(idController.text),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.blueAccent, Colors.indigoAccent],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blueAccent.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Backdrop filter blur overlay for processing loader
          if (isLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.blueAccent),
                          const SizedBox(height: 16),
                          Text(
                            "Searching Equipment Matrix...",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCornerAccent({required bool top, required bool left}) {
    const double size = 20;
    const double thickness = 4;
    final color = Colors.blueAccent.shade400;

    return Container(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            top: top ? 0 : null,
            bottom: top ? null : 0,
            left: left ? 0 : null,
            right: left ? null : 0,
            child: Container(
              width: size,
              height: thickness,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Positioned(
            top: top ? 0 : null,
            bottom: top ? null : 0,
            left: left ? 0 : null,
            right: left ? null : 0,
            child: Container(
              width: thickness,
              height: size,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
