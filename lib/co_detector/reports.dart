import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/api_service.dart';

class CODetectorReportsPage extends StatelessWidget {
  const CODetectorReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = CODetectorApiService();
    return ModuleReportsPage(
      moduleName: "CO Detector",
      moduleCode: CODetectorApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
