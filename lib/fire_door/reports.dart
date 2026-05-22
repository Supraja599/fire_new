import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/api_service.dart';

class FireDoorReportsPage extends StatelessWidget {
  const FireDoorReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = FireDoorApiService();
    return ModuleReportsPage(
      moduleName: "Fire Door",
      moduleCode: FireDoorApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
