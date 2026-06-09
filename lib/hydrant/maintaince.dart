import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class HydrantMaintenancePage extends StatelessWidget {
  const HydrantMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "Hydrant Maintenance",
      imagePath: "assets/firehydrant.webp",
      api: ModuleApiService.hydrant,
    );
  }
}
