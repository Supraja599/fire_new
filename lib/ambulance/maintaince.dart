import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class AmbulanceMaintenancePage extends StatelessWidget {
  const AmbulanceMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "Ambulance Maintenance",
      imagePath: "assets/ambulance.webp",
      api: ModuleApiService.ambulance,
    );
  }
}
