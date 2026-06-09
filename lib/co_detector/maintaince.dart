import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class CODetectorMaintenancePage extends StatelessWidget {
  const CODetectorMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "CO Detector Maintenance",
      imagePath: "assets/co_detector.webp",
      api: ModuleApiService.coDetector,
    );
  }
}
