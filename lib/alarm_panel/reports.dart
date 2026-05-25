import 'package:fire_new/services/module_api_service.dart';
import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
class AlarmPanelReportsPage extends StatelessWidget {
  const AlarmPanelReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ModuleApiService.alarmPanel;
    return ModuleReportsPage(
      moduleName: "Alarm Panels",
      moduleCode: ModuleApiService.alarmPanel.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
