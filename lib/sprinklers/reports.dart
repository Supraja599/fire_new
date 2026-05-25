import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
class SprinklerReportsPage extends StatelessWidget {
  const SprinklerReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ModuleApiService.sprinkler;
    return ModuleReportsPage(
      moduleName: "Fire Sprinklers",
      moduleCode: ModuleApiService.sprinkler.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
