import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
class EmergencyExitsReportsPage extends StatelessWidget {
  const EmergencyExitsReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ModuleApiService.emergencyExit;
    return ModuleReportsPage(
      moduleName: "Emergency Exits",
      moduleCode: ModuleApiService.emergencyExit.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
