import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
class HoseReelReportsPage extends StatelessWidget {
  const HoseReelReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ModuleApiService.hoseReel;
    return ModuleReportsPage(
      moduleName: "Hose Reels",
      moduleCode: ModuleApiService.hoseReel.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
