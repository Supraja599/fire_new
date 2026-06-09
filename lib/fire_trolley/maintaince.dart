import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class FireTrolleyMaintenancePage extends StatelessWidget {
  const FireTrolleyMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "Fire Trolley Maintenance",
      imagePath: "assets/fire_trolley.webp",
      api: ModuleApiService.fireTrolley,
    );
  }
}
