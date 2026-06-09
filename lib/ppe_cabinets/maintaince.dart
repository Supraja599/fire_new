import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class PPECabinetsMaintenancePage extends StatelessWidget {
  const PPECabinetsMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "PPE Cabinets Maintenance",
      imagePath: "assets/ppe_cabinets.webp",
      api: ModuleApiService.ppeCabinet,
    );
  }
}
