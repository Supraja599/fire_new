import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/api_service.dart';

class HeatDetectorReportsPage extends StatelessWidget {
  const HeatDetectorReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = HeatDetectorApiService();
    return ModuleReportsPage(
      moduleName: "Heat Detector",
      moduleCode: HeatDetectorApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
