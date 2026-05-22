import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/api_service.dart';

class CO2SystemReportsPage extends StatelessWidget {
  const CO2SystemReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = CO2SystemApiService();
    return ModuleReportsPage(
      moduleName: "CO2 System",
      moduleCode: CO2SystemApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
