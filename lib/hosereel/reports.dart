import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/apiservice.dart';

class HoseReelReportsPage extends StatelessWidget {
  const HoseReelReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = HoseReelApiService();
    return ModuleReportsPage(
      moduleName: "Hose Reels",
      moduleCode: HoseReelApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
