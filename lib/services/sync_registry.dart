import 'package:hive_flutter/hive_flutter.dart';
import 'package:fire_new/services/apiservice.dart';
import 'package:fire_new/alarm_panel/services/alarm_panel_api_service.dart';
import 'package:fire_new/ambulance/services/api_service.dart';
import 'package:fire_new/co2_system/services/api_service.dart';
import 'package:fire_new/emergency_comm/services/api_service.dart';
import 'package:fire_new/emergency_exits/services/api_service.dart';
import 'package:fire_new/emergency_lighting/services/api_service.dart';
import 'package:fire_new/emergency_shower/services/api_service.dart';
import 'package:fire_new/eye_wash/services/api_service.dart';
import 'package:fire_new/fire_blankets/services/api_service.dart';
import 'package:fire_new/fire_trolley/services/fire_trolley_api_service.dart';
import 'package:fire_new/first_aid/services/api_service.dart';
import 'package:fire_new/hosereel/services/apiservice.dart';
import 'package:fire_new/hydrant/services/hydrant_api_service.dart';
import 'package:fire_new/muster_points/services/api_service.dart';
import 'package:fire_new/pa_system/services/api_service.dart';
import 'package:fire_new/ppe_cabinets/services/api_service.dart';
import 'package:fire_new/scba_units/services/api_service.dart';
import 'package:fire_new/signage/services/api_service.dart';
import 'package:fire_new/smoke_detector/services/smoke_detector_api_service.dart';
import 'package:fire_new/spill_kits/services/api_service.dart';
import 'package:fire_new/splinkers/services/sprinkler_api_service.dart';
import 'package:fire_new/wind_sock/services/api_service.dart';
import 'package:fire_new/heat_detector/services/api_service.dart';
import 'package:fire_new/co_detector/services/api_service.dart';
import 'package:fire_new/fire_door/services/api_service.dart';

class SyncRegistry {
  static Map<String, Future<void> Function()> get _syncMap => {
    "fire_extinguisher": () => ApiService.syncModuleData(),
    "fire_alarm": () => AlarmPanelApiService().syncModuleData(),
    "ambulance": () => AmbulanceApiService().syncModuleData(),
    "suppression_system": () => CO2SystemApiService().syncModuleData(),
    "emergency_comm": () => EmergencyCommApiService().syncModuleData(),
    "exit_sign": () => EmergencyExitsApiService().syncModuleData(),
    "emergency_light": () => EmergencyLightingApiService().syncModuleData(),
    "safety_shower": () => EmergencyShowerApiService().syncModuleData(),
    "eyewash_station": () => EyeWashApiService().syncModuleData(),
    "fire_blanket": () => FireBlanketsApiService().syncModuleData(),
    "fire_trolley": () => FireTrolleyApiService().syncModuleData(),
    "first_aid_kit": () => FirstAidApiService().syncModuleData(),
    "hose_reel": () => HoseReelApiService().syncModuleData(),
    "hydrant": () => HydrantApiService().syncModuleData(),
    "muster_point": () => MusterPointsApiService().syncModuleData(),
    "pa_system": () => PASystemApiService().syncModuleData(),
    "ppe_station": () => PPECabinetsApiService().syncModuleData(),
    "scba_unit": () => SCBAUnitsApiService().syncModuleData(),
    "signage": () => SignageApiService().syncModuleData(),
    "smoke_detector": () => SmokeDetectorApiService().syncModuleData(),
    "spill_kit": () => SpillKitsApiService().syncModuleData(),
    "sprinkler": () => SprinklerApiService().syncModuleData(),
    "wind_sock": () => WindSockApiService().syncModuleData(),
    "heat_detector": () => HeatDetectorApiService().syncModuleData(),
    "co_detector": () => CODetectorApiService().syncModuleData(),
    "fire_door": () => FireDoorApiService().syncModuleData(),
  };

  static Future<void> syncEverything() async {
    final box = Hive.box('inspectionBox');
    final String role = box.get('role', defaultValue: 'user').toString().toLowerCase();
    final List<dynamic> assignedModulesData = box.get('modules', defaultValue: []);
    
    final Set<String> assignedCodes = assignedModulesData
        .map((m) => m['code']?.toString() ?? '')
        .where((code) => code.isNotEmpty)
        .toSet();

    final map = _syncMap;

    for (var entry in map.entries) {
      if (role == 'superadmin' || role == 'admin' || assignedCodes.contains(entry.key)) {
        try {
          print("🔄 Syncing module: ${entry.key}");
          await entry.value();
        } catch (e) {
          print("SyncRegistry Error [${entry.key}]: $e");
        }
      }
    }
  }
}
