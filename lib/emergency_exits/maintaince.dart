import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class EmergencyExitsMaintenancePage extends StatelessWidget {
  const EmergencyExitsMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "Emergency Exits Maintenance",
      imagePath: "assets/emergency_exit.webp",
      api: ModuleApiService.emergencyExit,
    );
  }
}
