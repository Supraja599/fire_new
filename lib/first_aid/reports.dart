import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
class FirstAidReportsPage extends StatelessWidget {
  const FirstAidReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ModuleApiService.firstAid;
    return ModuleReportsPage(
      moduleName: "First Aid",
      moduleCode: ModuleApiService.firstAid.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
