import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/smoke_detector_api_service.dart';

class SmokeDetectorReportsPage extends StatelessWidget {
  const SmokeDetectorReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = SmokeDetectorApiService();
    return ModuleReportsPage(
      moduleName: "Smoke Detectors",
      moduleCode: SmokeDetectorApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
