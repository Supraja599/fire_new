import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
class FireTrolleyReportsPage extends StatelessWidget {
  const FireTrolleyReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ModuleApiService.fireTrolley;
    return ModuleReportsPage(
      moduleName: "Fire Trolleys",
      moduleCode: ModuleApiService.fireTrolley.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
