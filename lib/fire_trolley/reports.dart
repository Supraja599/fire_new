import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/fire_trolley_api_service.dart';

class FireTrolleyReportsPage extends StatelessWidget {
  const FireTrolleyReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = FireTrolleyApiService();
    return ModuleReportsPage(
      moduleName: "Fire Trolleys",
      moduleCode: FireTrolleyApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
