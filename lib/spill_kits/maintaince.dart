import 'package:fire_new/services/module_api_service.dart';
import 'package:fire_new/widgets/module_maintenance_page.dart';
import 'package:flutter/material.dart';

class SpillKitsMaintenancePage extends StatelessWidget {
  const SpillKitsMaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleMaintenancePage(
      title: "Spill Kits Maintenance",
      imagePath: "assets/spill_kits.webp",
      api: ModuleApiService.spillKit,
    );
  }
}
