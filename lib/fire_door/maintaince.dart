import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class FireDoorMaintenancePage extends StatelessWidget {
  const FireDoorMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "Fire Door Maintenance",
      imagePath: "assets/fire_door.webp",
      api: ModuleApiService.fireDoor,
    );
  }
}
