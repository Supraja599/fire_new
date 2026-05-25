import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'package:fire_new/services/module_api_service.dart';

class EyeWashReportsPage extends StatelessWidget {
  const EyeWashReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ModuleApiService.eyeWash;
    return ModuleReportsPage(
      moduleName: "Eye Wash",
      moduleCode: api.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
