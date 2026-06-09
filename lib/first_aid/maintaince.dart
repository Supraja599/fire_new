import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class FirstAidMaintenancePage extends StatelessWidget {
  const FirstAidMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "First Aid Maintenance",
      imagePath: "assets/first_aid.webp",
      api: ModuleApiService.firstAid,
    );
  }
}
