import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
class EmergencyCommReportsPage extends StatelessWidget {
  const EmergencyCommReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ModuleApiService.emergencyComm;
    return ModuleReportsPage(
      moduleName: "Emergency Comm",
      moduleCode: ModuleApiService.emergencyComm.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
