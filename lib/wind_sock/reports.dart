import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/api_service.dart';

class WindSockReportsPage extends StatelessWidget {
  const WindSockReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = WindSockApiService();
    return ModuleReportsPage(
      moduleName: "Wind Sock",
      moduleCode: WindSockApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
