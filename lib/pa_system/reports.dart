import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/api_service.dart';

class PASystemReportsPage extends StatelessWidget {
  const PASystemReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = PASystemApiService();
    return ModuleReportsPage(
      moduleName: "PA System",
      moduleCode: PASystemApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
