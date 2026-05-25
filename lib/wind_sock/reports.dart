import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
class WindSockReportsPage extends StatelessWidget {
  const WindSockReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ModuleApiService.windSock;
    return ModuleReportsPage(
      moduleName: "Wind Sock",
      moduleCode: ModuleApiService.windSock.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
