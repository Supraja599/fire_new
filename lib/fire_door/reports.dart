import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
class FireDoorReportsPage extends StatelessWidget {
  const FireDoorReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ModuleApiService.fireDoor;
    return ModuleReportsPage(
      moduleName: "Fire Door",
      moduleCode: ModuleApiService.fireDoor.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
