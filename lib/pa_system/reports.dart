import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'package:fire_new/services/module_api_service.dart';

class PASystemReportsPage extends StatelessWidget {
  const PASystemReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ModuleApiService.paSystem;
    return ModuleReportsPage(
      moduleName: "PA System",
      moduleCode: api.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
