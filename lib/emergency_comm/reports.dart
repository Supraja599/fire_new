import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/api_service.dart';

class EmergencyCommReportsPage extends StatelessWidget {
  const EmergencyCommReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = EmergencyCommApiService();
    return ModuleReportsPage(
      moduleName: "Emergency Comm",
      moduleCode: EmergencyCommApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
