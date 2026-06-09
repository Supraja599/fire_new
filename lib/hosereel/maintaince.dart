import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class HoseReelMaintenancePage extends StatelessWidget {
  const HoseReelMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "Hose Reel Maintenance",
      imagePath: "assets/hosereel.webp",
      api: ModuleApiService.hoseReel,
    );
  }
}
