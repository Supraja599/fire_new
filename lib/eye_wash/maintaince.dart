import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class EyeWashMaintenancePage extends StatelessWidget {
  const EyeWashMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "Eye Wash Maintenance",
      imagePath: "assets/eye_wash.webp",
      api: ModuleApiService.eyeWash,
    );
  }
}
