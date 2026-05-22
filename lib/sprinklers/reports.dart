import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/sprinkler_api_service.dart';

class SprinklerReportsPage extends StatelessWidget {
  const SprinklerReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = SprinklerApiService();
    return ModuleReportsPage(
      moduleName: "Fire Sprinklers",
      moduleCode: SprinklerApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
