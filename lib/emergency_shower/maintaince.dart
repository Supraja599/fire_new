import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class EmergencyShowerMaintenancePage extends StatelessWidget {
  const EmergencyShowerMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "Emergency Shower Maintenance",
      imagePath: "assets/emergency_shower.webp",
      api: ModuleApiService.safetyShower,
    );
  }
}
