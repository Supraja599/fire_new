import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class CO2SystemMaintenancePage extends StatelessWidget {
  const CO2SystemMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "CO2 System Maintenance",
      imagePath: "assets/co2_system.webp",
      api: ModuleApiService.co2System,
    );
  }
}
