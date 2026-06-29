import 'package:hive_flutter/hive_flutter.dart';
import 'package:fire_new/services/apiservice.dart';
import 'package:fire_new/services/module_api_service.dart';

class SyncRegistry {
  static Map<String, Future<void> Function()> get _syncMap => {
    "fire_extinguisher": () => ApiService.syncModuleData(),
    "fire_alarm": () => ModuleApiService.alarmPanel.syncModuleData(),
    "ambulance": () => ModuleApiService.ambulance.syncModuleData(),
    "suppression_system": () => ModuleApiService.co2System.syncModuleData(),
    "emergency_comm": () => ModuleApiService.emergencyComm.syncModuleData(),
    "exit_sign": () => ModuleApiService.emergencyExit.syncModuleData(),
    "emergency_light": () => ModuleApiService.emergencyLight.syncModuleData(),
    "safety_shower": () => ModuleApiService.safetyShower.syncModuleData(),
    "eyewash_station": () => ModuleApiService.eyeWash.syncModuleData(),
    "fire_blanket": () => ModuleApiService.fireBlanket.syncModuleData(),
    "fire_trolley": () => ModuleApiService.fireTrolley.syncModuleData(),
    "first_aid_kit": () => ModuleApiService.firstAid.syncModuleData(),
    "hose_reel": () => ModuleApiService.hoseReel.syncModuleData(),
    "hydrant": () => ModuleApiService.hydrant.syncModuleData(),
    "muster_point": () => ModuleApiService.musterPoint.syncModuleData(),
    "pa_system": () => ModuleApiService.paSystem.syncModuleData(),
    "ppe_station": () => ModuleApiService.ppeCabinet.syncModuleData(),
    "scba_unit": () => ModuleApiService.scbaUnit.syncModuleData(),
    "signage": () => ModuleApiService.signage.syncModuleData(),
    "smoke_detector": () => ModuleApiService.smokeDetector.syncModuleData(),
    "spill_kit": () => ModuleApiService.spillKit.syncModuleData(),
    "sprinkler": () => ModuleApiService.sprinkler.syncModuleData(),
    "wind_sock": () => ModuleApiService.windSock.syncModuleData(),
    "heat_detector": () => ModuleApiService.heatDetector.syncModuleData(),
    "co_detector": () => ModuleApiService.coDetector.syncModuleData(),
    "fire_door": () => ModuleApiService.fireDoor.syncModuleData(),
    "sand_bucket": () => ModuleApiService.sandBucket.syncModuleData(),
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
