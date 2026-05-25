import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
class PPECabinetsReportsPage extends StatelessWidget {
  const PPECabinetsReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ModuleApiService.ppeCabinet;
    return ModuleReportsPage(
      moduleName: "PPE Cabinets",
      moduleCode: ModuleApiService.ppeCabinet.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
