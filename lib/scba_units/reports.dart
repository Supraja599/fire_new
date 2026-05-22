import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/api_service.dart';

class SCBAUnitsReportsPage extends StatelessWidget {
  const SCBAUnitsReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = SCBAUnitsApiService();
    return ModuleReportsPage(
      moduleName: "SCBA Units",
      moduleCode: SCBAUnitsApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
