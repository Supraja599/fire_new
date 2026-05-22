import 'package:flutter/material.dart';
import 'package:fire_new/common/module_reports_page.dart';
import 'services/alarm_panel_api_service.dart';

class AlarmPanelReportsPage extends StatelessWidget {
  const AlarmPanelReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final api = AlarmPanelApiService();
    return ModuleReportsPage(
      moduleName: "Alarm Panels",
      moduleCode: AlarmPanelApiService.moduleCode,
      getEquipmentList: api.getEquipmentList,
      getEquipmentByQuery: api.getEquipmentByQuery,
    );
  }
}
