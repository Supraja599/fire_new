import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/api_service.dart';

class EmergencyLightingReportsPage extends StatelessWidget {
  const EmergencyLightingReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = EmergencyLightingApiService();
    return ModuleReportsPage(
      moduleName: "Emergency Lighting",
      moduleCode: EmergencyLightingApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
