import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/hydrant_api_service.dart';

class HydrantReportsPage extends StatelessWidget {
  const HydrantReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = HydrantApiService();
    return ModuleReportsPage(
      moduleName: "Hydrant Points",
      moduleCode: HydrantApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
