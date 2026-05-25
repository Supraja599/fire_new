import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
class SCBAUnitsReportsPage extends StatelessWidget {
  const SCBAUnitsReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ModuleApiService.scbaUnit;
    return ModuleReportsPage(
      moduleName: "SCBA Units",
      moduleCode: ModuleApiService.scbaUnit.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
