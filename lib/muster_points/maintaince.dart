import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class MusterPointsMaintenancePage extends StatelessWidget {
  const MusterPointsMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "Muster Points Maintenance",
      imagePath: "assets/muster_points.webp",
      api: ModuleApiService.musterPoint,
    );
  }
}
