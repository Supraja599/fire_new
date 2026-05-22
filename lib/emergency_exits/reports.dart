import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/api_service.dart';

class EmergencyExitsReportsPage extends StatelessWidget {
  const EmergencyExitsReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = EmergencyExitsApiService();
    return ModuleReportsPage(
      moduleName: "Emergency Exits",
      moduleCode: EmergencyExitsApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
