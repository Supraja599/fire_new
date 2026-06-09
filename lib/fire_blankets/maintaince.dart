import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class FireBlanketsMaintenancePage extends StatelessWidget {
  const FireBlanketsMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "Fire Blankets Maintenance",
      imagePath: "assets/fire_blankets.webp",
      api: ModuleApiService.fireBlanket,
    );
  }
}
