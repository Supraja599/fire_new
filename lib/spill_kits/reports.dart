import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/api_service.dart';

class SpillKitsReportsPage extends StatelessWidget {
  const SpillKitsReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = SpillKitsApiService();
    return ModuleReportsPage(
      moduleName: "Spill Kits",
      moduleCode: SpillKitsApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
