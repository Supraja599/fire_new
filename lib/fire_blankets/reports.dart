import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
class FireBlanketsReportsPage extends StatelessWidget {
  const FireBlanketsReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ModuleApiService.fireBlanket;
    return ModuleReportsPage(
      moduleName: "Fire Blankets",
      moduleCode: ModuleApiService.fireBlanket.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
