import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/api_service.dart';

class AmbulanceReportsPage extends StatelessWidget {
  const AmbulanceReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = AmbulanceApiService();
    return ModuleReportsPage(
      moduleName: "Ambulance",
      moduleCode: AmbulanceApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
