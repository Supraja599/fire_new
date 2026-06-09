import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class AlarmPanelMaintenancePage extends StatelessWidget {
  const AlarmPanelMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "Alarm Panel Maintenance",
      imagePath: "assets/alarm_panel.webp",
      api: ModuleApiService.alarmPanel,
    );
  }
}
