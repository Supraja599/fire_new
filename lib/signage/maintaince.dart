import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class SignageMaintenancePage extends StatelessWidget {
  const SignageMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "Signage Maintenance",
      imagePath: "assets/signage.webp",
      api: ModuleApiService.signage,
    );
  }
}
