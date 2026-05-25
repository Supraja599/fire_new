import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'package:fire_new/services/module_api_service.dart';

class EmergencyLightingReportsPage extends StatelessWidget {
  const EmergencyLightingReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ModuleApiService.emergencyLight;
    return ModuleReportsPage(
      moduleName: "Emergency Lighting",
      moduleCode: api.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
