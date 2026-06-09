import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class EmergencyLightingMaintenancePage extends StatelessWidget {
  const EmergencyLightingMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "Emergency Lighting Maintenance",
      imagePath: "assets/emergency_lighting.webp",
      api: ModuleApiService.emergencyLight,
    );
  }
}
