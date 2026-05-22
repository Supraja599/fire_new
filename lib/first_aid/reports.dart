import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/api_service.dart';

class FirstAidReportsPage extends StatelessWidget {
  const FirstAidReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = FirstAidApiService();
    return ModuleReportsPage(
      moduleName: "First Aid",
      moduleCode: FirstAidApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
