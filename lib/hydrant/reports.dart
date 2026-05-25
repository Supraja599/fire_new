import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
class HydrantReportsPage extends StatelessWidget {
  const HydrantReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ModuleApiService.hydrant;
    return ModuleReportsPage(
      moduleName: "Hydrant Points",
      moduleCode: ModuleApiService.hydrant.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
