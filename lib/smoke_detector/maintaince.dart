import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class SmokeDetectorMaintenancePage extends StatelessWidget {
  const SmokeDetectorMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "Smoke Detector Maintenance",
      imagePath: "assets/smoke_detector.webp",
      api: ModuleApiService.smokeDetector,
    );
  }
}
