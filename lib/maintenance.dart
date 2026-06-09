import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "Fire Extinguisher Maintenance",
      imagePath: "assets/extinguisher.webp",
      api: ModuleApiService.extinguisher,
    );
  }
}
