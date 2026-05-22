import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/api_service.dart';

class FireBlanketsReportsPage extends StatelessWidget {
  const FireBlanketsReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = FireBlanketsApiService();
    return ModuleReportsPage(
      moduleName: "Fire Blankets",
      moduleCode: FireBlanketsApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
