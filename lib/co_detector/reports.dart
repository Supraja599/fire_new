import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
class CODetectorReportsPage extends StatelessWidget {
  const CODetectorReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ModuleApiService.coDetector;
    return ModuleReportsPage(
      moduleName: "CO Detector",
      moduleCode: ModuleApiService.coDetector.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
