import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class PASystemMaintenancePage extends StatelessWidget {
  const PASystemMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "PA System Maintenance",
      imagePath: "assets/pa_system.webp",
      api: ModuleApiService.paSystem,
    );
  }
}
