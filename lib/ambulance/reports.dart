import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
class AmbulanceReportsPage extends StatelessWidget {
  const AmbulanceReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ModuleApiService.ambulance;
    return ModuleReportsPage(
      moduleName: "Ambulance",
      moduleCode: ModuleApiService.ambulance.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
