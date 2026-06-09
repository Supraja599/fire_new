import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class HeatDetectorMaintenancePage extends StatelessWidget {
  const HeatDetectorMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "Heat Detector Maintenance",
      imagePath: "assets/heat_detector.webp",
      api: ModuleApiService.heatDetector,
    );
  }
}
