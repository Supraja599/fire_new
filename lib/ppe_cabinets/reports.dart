import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/api_service.dart';

class PPECabinetsReportsPage extends StatelessWidget {
  const PPECabinetsReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = PPECabinetsApiService();
    return ModuleReportsPage(
      moduleName: "PPE Cabinets",
      moduleCode: PPECabinetsApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
