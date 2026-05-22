import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/api_service.dart';

class MusterPointsReportsPage extends StatelessWidget {
  const MusterPointsReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = MusterPointsApiService();
    return ModuleReportsPage(
      moduleName: "Muster Points",
      moduleCode: MusterPointsApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
