import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class EmergencyCommMaintenancePage extends StatelessWidget {
  const EmergencyCommMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "Emergency Comm Maintenance",
      imagePath: "assets/emergency_comm.webp",
      api: ModuleApiService.emergencyComm,
    );
  }
}
