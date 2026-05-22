import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/api_service.dart';

class EyeWashReportsPage extends StatelessWidget {
  const EyeWashReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = EyeWashApiService();
    return ModuleReportsPage(
      moduleName: "Eye Wash",
      moduleCode: EyeWashApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
