import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class SprinklerMaintenancePage extends StatelessWidget {
  const SprinklerMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "Sprinkler Maintenance",
      imagePath: "assets/sprinkler.webp",
      api: ModuleApiService.sprinkler,
    );
  }
}
